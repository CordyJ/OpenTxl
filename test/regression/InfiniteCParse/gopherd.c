/********************************************************************
 * Modification of VMS gopher server to conform
 * more closely to 1.2.1.6; JLW@PSULIAS.PSU.EDU
 ********************************************************************/

#ifndef GOPHERD_C
#define GOPHERD_C 1
#endif

#include "gopherd.h"
#include <stdarg.h>
#include <descrip.h>
#include <unixlib.h>
#ifdef VMS
#include <prvdef.h>
#ifdef UCX
#include <ucx$inetdef.h>
#endif /* UCX */
#endif /* VMS */

void LOGGopher(int sockfd, char *fmt,...);
void VMSdisableAllPrv();
FILE *Build_Lookaside(char *path, char *file, GopherStruct *gs);
char *vms_errno_string();
int Continuation(char* buf, FILE* file, int max, char cont);

char VMSpath[256];
char NoSuchFile[256];
char TooBusy[256];
char BummerMsg[256];
char RangeErr[256];
char SyntaxErr[256];
char BaddirMsg[256];
static
 char	ClientWentAway[] = "Client went away!";
#ifdef VMS
#define	STRerror(a) strerror(EVMSERR, vaxc$errno)
extern int vaxc$errno_stv;
extern double sysload;
extern char log_alq[10];
extern char log_deq[10];
char *Validate_Filespec(char *);
int  gopher_traceback();
char *WWW_to_VMS(char *, char);
static
    struct
	{   
	    int socket;
	    char *tx;
	 }  traceback;
static unsigned long condition;
static
    struct _exit_block
	{
	    unsigned long fwdlink;
	    unsigned long routine$;
	    unsigned long count;
	    unsigned long condition;
	}   gopher_traceback_blk =
	   {0, (unsigned long) &gopher_traceback,1, (unsigned long) &condition};
#else
#define STRerror(a) strerror(a)
#endif
static BOOLEAN NoDOT;

/* This function is called on a read timeout from the network */

#include <signal.h>
#include <setjmp.h>
jmp_buf env;

SIGRETTYPE read_timeout(sig)
  int sig;
{
     longjmp(env,1);
}

/*
 * This routine finds out the hostname of the server machine.
 * It uses a couple of methods to find the fully qualified 
 * Domain name
 */

char *
GetDNSname(char *backupdomain)
{
     static char DNSname[MAXHOSTNAMELEN];
     struct hostent *hp;
     char *cp;

     cp = GDCgetHostname(Config);
     if (*cp != '\0')
	  return(cp);

     DNSname[0] = '\0';
     /* Work out our fully-qualified name, for later use */
     
     if (gethostname(DNSname, MAXHOSTNAMELEN) != 0) {
	  LOGGopher(-99,"fatal: Cannot determine the name of this host");
     }

     /* Now, use gethostbyname to (hopefully) do a nameserver lookup */
     hp = gethostbyname( DNSname);

     /*
      ** If we got something, and the name is longer than hostname, then
      ** assume that it must the the fully-qualified hostname
      */
     if ( hp!=NULL && strlen(hp->h_name) > strlen(DNSname) ) 
	  strncpy( DNSname, hp->h_name, MAXHOSTNAMELEN );
     else
	  strcat(DNSname, backupdomain);

     return(DNSname);
}

/*
 * Tries to figure out what the currently connected port is.
 * 
 * If it's a socket then it will return the port of the socket, 
 * if it isn't a socket then it returns -1.
 */

int GetPort(int fd)
{
     struct sockaddr_in serv_addr;

     int length = sizeof(serv_addr);
     
     /** Try to figure out the port we're running on. **/
     
     if (getsockname(fd, (struct sockaddr *) &serv_addr,&length) == 0)
	  return(ntohs(serv_addr.sin_port));
     else
	  return(-1);

}

/*
 * This function returns a socket file descriptor bound to the given port,
 *  with socket options SO_REUSADDR set true and SO_LINGER reset false.
 *  Once binding is completed, SYSPRV can be discarded for the rest of the
 *  GOPHERD run....
 */
int
bind_to_port(int port) 
{
    struct sockaddr_in serv_addr;
    struct linger linger;
    int reuseaddr = 1;
    int sockfd;
#ifdef VMS
    union prvdef prvadr;
#endif
     
     if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
	  LOGGopher(-99,"fatal: can't open stream socket, %s",
						vms_errno_string());
     }
     /*
     *  Set the "REUSEADDR" option on this socket, allowing us to bind() to 
     *	it even if there already is a connection, instead of getting an 
     *	"Address already in use" error.
     */
     if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (char *)&reuseaddr,
			sizeof(reuseaddr)) < 0) {
	  LOGGopher(-99,"fatal: can't set socket REUSEADDR, %s",
					vms_errno_string());
	}     
     
     /** Bind our local address so that the client can send to us **/
     
     bzero((char *) &serv_addr, sizeof(serv_addr));
     serv_addr.sin_family 		= AF_INET;
     serv_addr.sin_addr.s_addr 	= htonl(INADDR_ANY);
     serv_addr.sin_port		= htons(port);
     
     if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) <0) {
	  LOGGopher(-99, "fatal: can't bind local address, %s",
				vms_errno_string());
     }
     /*
     *  Set the "NO LINGER" option on this socket, causing unsent messages 
     *	to be discarded if a client disconnects unexpectedly.
     */
     linger.l_onoff = linger.l_linger = 0;
     if (setsockopt(sockfd, SOL_SOCKET, SO_LINGER, (char *)&linger,
			sizeof(linger)) < 0) {
	  LOGGopher(-99,"fatal: can't reset socket LINGER, %s",
					vms_errno_string());
	}     
#ifdef VMS
    bzero((char *) &prvadr, sizeof(prvadr));
    prvadr.prv$v_sysprv = 1;
    if (SS$_NORMAL != (vaxc$errno = SYS$SETPRV (DEBUG, &prvadr, 0, 0))) {
	  LOGGopher(-1,"Can't discard PRIVS, %s", STRerror(errno));
    }
#endif
    return(sockfd);
}

#ifdef VMS
/*	Disable all privileges except TMPMBX and NETMBX
**	------------------------------------------------
**
**      F.Macrides (MACRIDES@SCI.WFEB.EDU) -- 21-Feb-1994
**	(based on code from H.Flowers <flowers@narnia.memst.edu>)
**
**	Note that if an INETD server process is running with a system UIC
**	(like the SYSTEM account has), turning off SYSPRV will have little
**	effect due to SYSTEM rights identifiers, but we should turn off all
**	these other privs, and may as well turn off SYSPRV too.
*/
void
VMSdisableAllPrv(void)
{
    union prvdef prvadr;

    bzero((char *) &prvadr, sizeof(prvadr));
    prvadr.prv$v_cmkrnl = 1;      
    prvadr.prv$v_cmexec = 1;      
    prvadr.prv$v_sysnam = 1;      
    prvadr.prv$v_grpnam = 1;      
    prvadr.prv$v_allspool = 1;    
    prvadr.prv$v_detach = 1;      
    prvadr.prv$v_diagnose = 1;    
    prvadr.prv$v_log_io = 1;      
    prvadr.prv$v_group = 1;       
    prvadr.prv$v_noacnt = 1;      
    prvadr.prv$v_prmceb = 1;      
    prvadr.prv$v_prmmbx = 1;      
    prvadr.prv$v_pswapm = 1;      
    prvadr.prv$v_setpri = 1;      
    prvadr.prv$v_setprv = 1;      
    prvadr.prv$v_world = 1;       
    prvadr.prv$v_mount = 1;       
    prvadr.prv$v_oper = 1;        
    prvadr.prv$v_exquota = 1;     
    prvadr.prv$v_volpro = 1;      
    prvadr.prv$v_phy_io = 1;      
    prvadr.prv$v_bugchk = 1;      
    prvadr.prv$v_prmgbl = 1;      
    prvadr.prv$v_sysgbl = 1;      
    prvadr.prv$v_pfnmap = 1;      
    prvadr.prv$v_shmem = 1;       
    prvadr.prv$v_sysprv = 1;      
    prvadr.prv$v_bypass = 1;      
    prvadr.prv$v_syslck = 1;      
    prvadr.prv$v_share = 1;       
    prvadr.prv$v_upgrade = 1;     
    prvadr.prv$v_downgrade = 1;   
    prvadr.prv$v_grpprv = 1;      
    prvadr.prv$v_readall = 1;     
    prvadr.prv$v_security = 1;    
}
#endif /* VMS */

main(int argc, char *argv[])
{
     int		childpid;
     int		sockfd = 0, newsockfd;
     int		clilen;
     struct sockaddr_in	cli_addr;
     boolean		OptionsRead = FALSE;

     /*** for getopt processing ***/
     int c;
#ifndef VMS
     extern char *optarg;
     extern int optind;
     int errflag =0;
#endif

#ifdef VMS
     static
	int	case_blind = LNM$M_CASE_BLIND;
     static
     	int	trn_len;
     char	trn_name[80];
     $DESCRIPTOR(dsc$sys_table, "LNM$SYSTEM_TABLE");
     $DESCRIPTOR(dsc$restart,   RESTART);
     static
	struct 
	itmlst lnm_item[] = { { 0, LNM$_STRING, 0, &trn_len },
					     { 0, 0, 0, 0 } };
     lnm_item[0].bufadr = trn_name;
     lnm_item[0].length = sizeof(trn_name);
     traceback.socket = -1;
     traceback.tx     = NULL;
     VAXC$ESTABLISH (gopher_traceback);
     SYS$DCLEXH (&gopher_traceback_blk);
#endif

     pname = argv[0];

     /*** Check argv[0], see if we're running as gopherls, etc. ***/

     RunServer = RunLS = RunIndex = FALSE;

     if (strstr(argv[0], "gopherls") != NULL) {
	  RunLS = TRUE;
     } else if (strstr(argv[0], "gindexd") != NULL) {
	  RunIndex = TRUE;
	  dochroot = FALSE;
     } else 
	  RunServer = TRUE;  /** Run the server by default **/

     Config = GDCnew();	/** Set up the general configuration **/

#ifdef VMS
#if defined(MULTINET) || defined(WOLLONGONG)
    /*
     *  The fopen() in GDCfromFile() opens and closes SYS$INPUT
     */
     {
          int status;
          unsigned short chan;
          $DESCRIPTOR(desc, "SYS$INPUT");
         /*
	  *  See if we're running under Inetd/MULTINET_SERVER
	  *  and if so, get a channel to the socket.
	  */
          if (strstr(getenv("SYS$INPUT"), "_INET")) {
               status = sys$assign(&desc, &chan, 0, 0, 0);
               if (!(status & 1))
                    exit(status);
               sockfd = (int) chan;
               RunFromInetd = TRUE;
	  }
     }
#endif /* MultiNet or Wollongong */

#if defined(UCX) && defined(UCX$C_AUXS)
	 /*
	  *  This socket call will try to get the client connection from
	  *  the AUX Server.  If the socket call fails, assume we are
	  *  running as a detached process.  Otherwise, we are running
	  *  from the AUX server.
	  */
	  if ((sockfd = socket (UCX$C_AUXS, 0, 0)) != -1)
	       RunFromInetd = TRUE;
#endif /* UCX v2+ */

     if (RunFromInetd) {
    /*
     *  Track down the configuration file.  Everything this server process
     *  needs to know is now passed through that file. -- F.Macrides
     */
          int newport = 0;
          char *ConfigFile = (char *) malloc(sizeof(char)*256);

	 /* 
	  *  In multiserver environments, the port number is appended
	  *  to a system logical for each server's configuration file.
	  */
	  if ((newport = GetPort(sockfd)) < 0)
	       exit(SS$_NOIOCHAN);
	  sprintf(ConfigFile, "GOPHER_CONFIG%d", newport);
	  if (getenv(ConfigFile) != NULL) {
	       GDCfromFile(Config, getenv(ConfigFile));
	  } else {
	      /*
	       *  Try the system logical without a numeric suffix.
	       */
	       strcpy(ConfigFile, "GOPHER_CONFIG");
	       if (getenv(ConfigFile) != NULL) {
	            GDCfromFile(Config, getenv(ConfigFile));
	       } else {
	           /*
	            *  Must be an explicit filespec in CONF.H
	            */
	            GDCfromFile(Config, CONF_FILE);
	       }
	  }
	  free(ConfigFile);

         /*
	  *  Make sure the configuration file didn't set these wrong.
	  */
	  GDCsetInetdActive(Config, TRUE);
	  GDCsetPort(Config, (GopherPort = newport));

	  OptionsRead = TRUE;

	 /*
	  *  Turn off all privs except TMPMBX and NETMBX
	  */
	  VMSdisableAllPrv();
     }

/***	VMS command line options are cast to lowercase in C programs, unless
            each argument was double-quoted.  Furthermore, many of the options
	    are pretty irrelevant for debugging purposes, and passing command
	    line options to a VMS detatched process isn't particularly easy.
	    
	    So command line options will be used in VMS only for debugging,
	    when not running under Inetd/MULTINET_SERVER, and they will be
	    restricted to the configuration file and port number.  They'll
	    all be positional:

	    $ gopher_debug [[[debug] port] config]
***/
     if (argc>1 && !RunFromInetd) {
        GDCfromFile(Config, argv[--argc]);
        OptionsRead = TRUE;
	if (argc>1 && !RunFromInetd) {
	    GDCsetPort(Config, (GopherPort = atoi(argv[--argc])));
	    if (argc>1)
		DEBUG = TRUE;
	    }
     }
     dochroot = FALSE;

#else /*** Unix command line options: ***/
     while ((c = getopt(argc, argv, "mCDIcL:l:o:u:U:")) != -1)
	  switch (c) {
	  case 'D':
	       DEBUG = TRUE;
	       break;

	  case 'I':
	       RunFromInetd = TRUE;
	       break;

	  case 'C':
	       Caching = FALSE;
	       break;

	  case 'm':
		if (RunIndex)
			MacIndex = TRUE;
		break;

	  case 'c':	
	       dochroot = FALSE;
	       if (!RunFromInetd) {
		    printf("Not using chroot() - be careful\n");
		    if ( getuid() == 0 || geteuid() == 0 )
			 printf("You should run without root perms\n");
	       }
	       break;
	  case 'L':  /** Load average at which to restrict usage **/
	       GDCsetMaxLoad(gdc, atof(optarg));
	       break;
	  case 'l':  /** logfile name **/
	       if (*optarg == '/')
		    GDCsetLogfile(Config, optarg);
	       else {
		    char tmpstr[256];
		    
		    getwd(tmpstr);
		    strcat(tmpstr, "/");
		    strcat(tmpstr, optarg);
		    
		    GDCsetLogfile(Config, tmpstr);
	       }
	       break;

	  case 'o': /** option file **/
	       if (*optarg == '/')
		    GDCfromFile(Config, optarg);
	       else {
		    char tmpstr[256];
		    getwd(tmpstr);
		    strcat(tmpstr, "/");
		    strcat(tmpstr, optarg);
		    GDCfromFile(Config, tmpstr);
	       }
	       OptionsRead = TRUE;
	       break;

	  case 'u':
	       {
		    struct passwd *pw = getpwnam( optarg );
		    if ( !pw ) {
			 fprintf(stderr,
			      "Could not find user '%s' in passwd file\n",
			      optarg);
			 errflag++;
		    } else {
			 uid = pw->pw_uid;
			 if (!RunFromInetd) {
			      printf("Running as user '%s' (%d)\n",
				   optarg, uid);
			 }
		    }
	       }
	       break;

	  case 'U':	/* set uid to use */
	       uid = atoi( optarg );
	       if (!RunFromInetd) {
		    printf("Running using uid %d\n", uid);
	       }
	       break;
	  case '?':
	  case 'h':
	       errflag++;
	       break;
	  }


     if (errflag) {
	  fprintf(stderr, "Usage: %s [-CDIc] [-u userid] [-U uid] [-s securityfile] [-l logfile] <datadirectory> <port>\n", argv[0]);
	  fprintf(stderr, "   -C  turns caching off\n");
	  fprintf(stderr, "   -D  enables copious debugging info\n");
	  fprintf(stderr, "   -I  enable \"inetd\" mode\n");
	  fprintf(stderr, "   -c  disable chroot(), use secure open routines instead\n");
	  fprintf(stderr, "   -u  specifies the username for use with -c\n");
	  fprintf(stderr, "   -U  specifies the UID for use with -c\n");
	  fprintf(stderr, "   -o  override the default options file '%s'\n", CONF_FILE);
	  fprintf(stderr, "   -l  specifies the name of a logfile\n");
		  
	  exit(-1);
     }

     if (uid == -2) 
	  uid = getuid();  /** Run as current user... **/

     if ( uid == 0 && !RunFromInetd )
	  printf("Warning! You really shouldn't run the server as root!...\n");


     if (optind < argc) {
	  GDCsetDataDir(Config, argv[optind]);
	  optind++;
     } else if (RunLS)
	  GDCsetDataDir(Config, "/");

     if (optind < argc) {
	  GDCsetPort(Config, (GopherPort = atoi(argv[optind])));
	  optind++;
     }
#endif /* VMS */

     /** Read the options in, if not overridden **/
     if (OptionsRead == FALSE)
	  GDCfromFile(Config, CONF_FILE);
     /** Were the FTPPort, EXECPort or SRCHPort were unspecified? **/
     if (GDCgetFTPPort(Config) == -1)
	GDCsetFTPPort(Config,GDCgetPort(Config));
     if (GDCgetEXECPort(Config) == -1)
	GDCsetEXECPort(Config,GDCgetPort(Config));
     if (GDCgetSRCHPort(Config) == -1)
	GDCsetSRCHPort(Config,GDCgetPort(Config));
     /** Get the lookaside file format **/
     if (*GDCgetLookAside(Config) != '\0') {
	char lookaside[256];
#ifdef VMS
	strcpy(lookaside, GDCgetLookAside(Config));
	strcat(lookaside, ".DIR");
#else
	strcpy(lookaside, GDCgetLookAside(Config));
#endif
	ExtAdd(Config->Extensions, A_ERROR, "","",lookaside);
     }

#ifdef VMS
     /** Load the RESTART logical into its descriptor **/
     if (*GDCgetRestart(Config) != '\0') {
	dsc$restart.dsc$a_pointer = GDCgetRestart(Config);
	dsc$restart.dsc$w_length = strlen(GDCgetRestart(Config));
     }
#endif

     /** Get the message file info **/
     sprintf(NoSuchFile,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"no_such_file");
     sprintf(TooBusy,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"2busy");
     sprintf(BummerMsg,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"bummer");
     sprintf(RangeErr,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"range");
     sprintf(SyntaxErr,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"syntax");
     sprintf(BaddirMsg,"0%s%s%s.%s",GDCgetDataDir(Config),
			GDCgetHiddenPrefix(Config), "server_error",
				"baddir");

     if (RunLS) {
	  GDCsetHostname(Config,(Zehostname = GetDNSname(DOMAIN_NAME)));
	  Caching = FALSE;

	  fflush(stdout);
	  chdir(GDCgetDataDir(Config));

	  listdir(fileno(stdout), "/");
	  exit(0);
     }

     if (!RunFromInetd) {
	  printf("VMSGopherServer version %s-%s\n", GOPHERD_VERSION,
				    PATCH_LEVEL);
	  printf("Gopher Server, Copyright 1991,92,93 the Regents of the University of Minnesota\n");
	  printf("See the file 'Copyright' for conditions of use\n");
	  printf("Data directory is %s\n", GDCgetDataDir(Config));
	  printf("Port is %d\n", GDCgetPort(Config));
	  printf("Image is %s\n", pname);
	  printf("PID is %x\n", getpid());
	  if (GDCgetLogfile(Config))
		printf("Logging to File %s\n", GDCgetLogfile(Config));

	  LOGGopher(-1, "================================");
	  LOGGopher(-1, "Starting %x %s", getpid(), pname);
     }	  	  

     if (chdir(GDCgetDataDir(Config))) {
	  LOGGopher(-99,"fatal: cannot change to data directory!! %s, %s",
				    GDCgetDataDir(Config),STRerror(errno));
     }
     fflush(stderr);
     fflush(stdout);


     /** Ask the system what host we're running on **/
     
     GDCsetHostname(Config, (Zehostname = GetDNSname(DOMAIN_NAME)));
     
     if (RunFromInetd) {
	  /** Ask the system which port we're running on **/
	  int newport=0;
	  if ((newport = GetPort(sockfd)) != 0)
	    GDCsetPort(Config, (GopherPort = newport));
	  
	  /*** Do the stuff for inetd ***/

	  while(do_command(sockfd)!=0);	/* process the request */
#ifdef VMS
	  traceback.socket = -1;
	  traceback.tx     = NULL;
	  SYS$CANEXH (&gopher_traceback_blk);
#endif     
	  return;
     }

     /** Open a TCP socket (an internet stream socket **/
     sockfd = bind_to_port(GDCgetPort(Config));
     
     listen(sockfd, 5);
     
     for ( ; ; ) {
	  /*
	   * Wait for a connection from a client process.
	   * This is an example of a concurrent server.
	   */
#ifdef VMS
	  if (SS$_NORMAL == (c = SYS$TRNLNM(&case_blind, &dsc$sys_table,
					&dsc$restart, 0, &lnm_item))) {
	    trn_name[trn_len] = '\0';
	    LOGGopher(-1,"Server %x Stopped (%s = '%s')",getpid(),
				dsc$restart.dsc$a_pointer, trn_name);
	    printf("Server Shutdown, %s = '%s'",
				dsc$restart.dsc$a_pointer, trn_name);
	    SYS$CANEXH (&gopher_traceback_blk);
	    break;
	  }
#endif	  
	  clilen = sizeof(cli_addr);
	  newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr,
			     &clilen);
	  
	  if (newsockfd < 0)
	       LOGGopher(newsockfd, "server: accept error, %s",
					vms_errno_string());
	  
          while(do_command(newsockfd)!=0);{}	/* process the request */
#ifdef VMS
	  traceback.socket = -1;
	  traceback.tx     = NULL;
#endif     
	  closenet(newsockfd);		    /* parent process */

     }
}

/*
 *
 *  Code stolen from nntp.....
 *
 * inet_netnames -- return the network, subnet, and host names of
 * our peer process for the Internet domain.
 *
 *      Parameters:     "sock" is our socket
 *                      "host_name"
 *                      is filled in by this routine with the
 *                      corresponding ASCII names of our peer.
 *       
 *                      if there doesn't exist a hostname in DNS etal,
 *                      the IP# will be inserted for the host_name
 *
 *                      "ipnum" is filled in with the ascii IP#
 *      Returns:        Nothing.
 *      Side effects:   None.
 */

void
inet_netnames(int sockfd, char *host_name, char *ipnum)
{
     struct sockaddr_in      sa;
     int                     length;
     u_long                  net_addr;
     struct hostent          *hp;

     length = sizeof(sa);
     if (getpeername(sockfd, (struct sockaddr *)&sa, &length) == -1) {
          LOGGopher(-2, "getpeername() failure: %s", vms_errno_string());
	  strcpy(ipnum,"Unknown");
	  strcpy(host_name,"Unknown");
	  return;
     }
     strcpy(ipnum, (char *) inet_ntoa(sa.sin_addr));
     if (host_name != ipnum)
          strcpy(host_name, (char *) inet_ntoa(sa.sin_addr));

     hp = gethostbyaddr((char *) &sa.sin_addr,
			sizeof (sa.sin_addr.s_addr), AF_INET);
     
     if (hp != NULL)
	  (void) strcpy(host_name, hp->h_name);
     else {
/**	  LOGGopher(-2, "gethostbyaddr(%s) failure", ipnum); /**Diagnostic**/
	  strcpy(host_name, ipnum);
     }
}

/*
 * This finds the current peer and the time and  jams it into the
 * logfile (if any) and adds the message at the end
 */
void
LOGGopher(int sockfd, char *fmt,...)
{
     time_t          Now;
     char	     NowBuf[26];
     char	     *cp;
     char            buf[286+MAXLINE];
     va_list	     arg_ptr;

     va_start(arg_ptr, fmt);
     vsprintf(buf,fmt,arg_ptr);
     va_end(arg_ptr);
     time(&Now);
     cp = (char *) ctime(&Now);
     ZapCRLF(cp);
     cp=strcpy(NowBuf,cp);
     if (GDCgetLogfile(Config)) {
#ifdef VMS
	LOGFileDesc = fopen(GDCgetLogfile(Config),"a",log_alq,log_deq);
#else
	LOGFileDesc = fopen(GDCgetLogfile(Config),"a");
#endif
	if (LOGFileDesc != NULL) {
	    if (strlen(fmt)) {
		fprintf(LOGFileDesc, "%s p%d %s : %s\n", cp,
				GDCgetPort(Config), CurrentPeerName, buf);
		fflush(LOGFileDesc);
	    }
	    else
	      if (DEBUG)
		sprintf(buf,"Testing logfile %s",GDCgetLogfile(Config));
	    fclose(LOGFileDesc);
	 }
	 else {
	    if (strlen(fmt) && !RunFromInetd) {
		printf("Can't open the logfile %s - (%d) %s\n", 
#ifdef VMS
				    GDCgetLogfile(Config), vaxc$errno, STRerror(errno));
#else
				    GDCgetLogfile(Config), errno, STRerror(errno));
#endif
		printf("%s p%d %s : %s\n", cp,
				    GDCgetPort(Config), CurrentPeerName, buf);
#ifdef VMS
		if (vaxc$errno == RMS$_ACC) {
		    printf("STV=(%d) %s\n", vaxc$errno_stv,
				    vaxc$errno_stv?
					strerror(EVMSERR, vaxc$errno_stv):"");
		    exit(vaxc$errno);
		}
#endif
	    }
	 }
     }
     if ((!GDCgetLogfile(Config) || DEBUG) && strlen(fmt) && !RunFromInetd)
	printf("%s p%d %s : %s\n", cp, 
				GDCgetPort(Config), CurrentPeerName, buf);
     if (sockfd == -99) {
	DEBUG = TRUE;
	LOGGopher(-1,"server shutdown!!!");
	exit(-1);
     }
}

#ifdef GOPHER_MAILSPOOL
process_mailfile(int sockfd, char *Mailfname)
{
     FILE *Mailfile;
     char Zeline[MAXLINE];
     char outputline[MAXLINE];
     char Title[MAXLINE];
     long Startbyte=0, Endbyte, Bytecount;

     Mailfile = fopen(Mailfname, "r");

     if (Mailfile == NULL) {
	  writestring(sockfd, "- Cannot access file\r\n.\r\n");
	  return;
     }

     while (fgets(Zeline, MAXLINE, Mailfile) != NULL) {

	  if (strncmp(Zeline, "Subject: ", 9)==0) {
	       strcpy(Title, Zeline + 9);
	       ZapCRLF(Title);
	       if (DEBUG)
		    printf("Found title %s", Title);
	  }
	  
	  if (strncmp(Zeline, "From ", 5) == 0) {
	       Endbyte = Bytecount;

	       if (Endbyte != 0) {
		    sprintf(outputline, "0%s\tR%d-%d-%s\t%s\t%d\r\n", 
			    Title, Startbyte, Endbyte, Mailfname, 
			    GDCgetHostname(Config), GDCgetPort(Config));
		    writestring(sockfd, outputline);
		    
		    Startbyte=Bytecount;
		    *Title = '\0';
	       }
	  }

	  Bytecount += strlen(Zeline);
     }

     if (*Title != '\0') {
	  sprintf(outputline, "0%s\tR%d-%d-%s\t%s\t%d\r\n", 
		  Title, Startbyte, Endbyte, Mailfname, 
			    GDCgetHostname(Config), GDCgetPort(Config));
	  writestring(sockfd, outputline);
     }	  

     writestring(sockfd, ".\r\n");
}
#endif

boolean
CanAccess(sockfd, access)
  int sockfd;
  int access;
{
     boolean		result;

     switch(access) {
     case ACC_READ:
          return(GDCCanRead(Config, CurrentPeerName, CurrentPeerIP));
     case ACC_BROWSE:
          return(GDCCanBrowse(Config, CurrentPeerName, CurrentPeerIP));
     case ACC_SEARCH:
          return(GDCCanSearch(Config, CurrentPeerName, CurrentPeerIP));
     }
}

int
do_command(int sockfd)
{
     char inputline[MAXLINE];
     int  length;		/* Length of the command line */
     char *selstr, *cp, *HTTP2line;

     /** Make sure nothing left over from prior use **/
     EXECargs = NULL;
     UsingHTML = FALSE;
     NoDOT = FALSE;
     condition = 0;
     strcpy(CurrentPeerName, "Unknown");
     strcpy(CurrentPeerIP, "Unknown");

     /** Enable timeout for inet_netname() and readline() routines **/
     (void) signal(SIGALRM,read_timeout);
     (void) alarm(GDCgetReadTimeout(Config)); /* 5 minutes */

     if(setjmp(env)) {
	  LOGGopher(sockfd,"inet_netname/readline: Timed out!");
	  Abortoutput(sockfd, GDCgetBummerMsg(Config),"bummer");
	  return(FALSE);
     }

     /** Make sure we have a connected, known client */
     inet_netnames(sockfd, CurrentPeerName, CurrentPeerIP);
     if (strcmp(CurrentPeerName,"Unknown") == 0) {
	  do {
               length = readline(sockfd, inputline, MAXLINE);
                    ZapCRLF(inputline);
          } while (length > 0 && strlen(inputline) != 0);
          closenet(sockfd);
          return(FALSE);
     }

     /*** Reopen the log file ***/
     LOGGopher(-1,"");

     if(LoadTooHigh() && (strncasecmp(TooBusy,selstr,strlen(TooBusy))!=0)) {
	LOGGopher(sockfd, "System Load (%g) Too High", sysload);
	Abortoutput(sockfd, "System is too busy right now.","2busy");
	return(FALSE);
     }

     /** Get the line **/
     length = readline(sockfd, inputline, MAXLINE);
     if (length <= 0) {
	  closenet(sockfd);
	  LOGGopher(-2, ClientWentAway);
	  return(FALSE);
     }
     ZapCRLF(inputline);

     /*
      * Decide if we're an HTML server or not...
      */

     if (strncmp(inputline, "GET ", 4) == 0) {

	  UsingHTML = TRUE;
	  NoDOT = TRUE;

	  /** Check for Unix root directory designator **/
	  if (*(inputline+4) == '/')
	       selstr = inputline+5;
	  else
	       selstr = inputline+4;

	  /** Convert the hex things back to text... ***/
	  Fromhexstr(selstr, selstr);

	  /** Check for http flag from a gopher server's tuple **/
          if (strncmp(selstr, "GET ", 4) == 0) {
	       if (*(selstr+4) == '/')
	            selstr = selstr+5;
	       else
	            selstr = selstr+4;
	  }

	  /** Trim off HTTP2 trailers, if present **/
	  if ((cp=strstr(selstr, " HTTP/1.0")) != NULL) {
	       *cp = '\0';

               /** Clear the Accept:, User-Agent: and From: **/
	       /** fields from the receive buffer           **/
	       HTTP2line = (char *) malloc(sizeof(char)*MAXLINE);
	       do {
                    length = readline(sockfd, HTTP2line, MAXLINE);
                    ZapCRLF(HTTP2line);
               } while (length > 0 && strlen(HTTP2line) != 0);
	       free(HTTP2line);
	  }
     }
     else
	  selstr = inputline;

     /** Disable the alarm signal **/
     (void) alarm(0);
     (void) signal(SIGALRM,SIG_IGN);

     /** Change our root directory **/
     if (chdir(GDCgetDataDir(Config))) {
	  Abortoutput(sockfd, "Data Directory dissappeared!","data_gone");
	  LOGGopher(-1, "Cannot change to data directory!! %s, %s",
				    GDCgetDataDir(Config),STRerror(errno));
	  return(FALSE);
     }

     /*** With the funky new capability system we can just check the
          first letter, end decide what the object refers to. ***/
#ifdef VMS
     traceback.socket = sockfd;
     traceback.tx     = inputline;
#endif     
     switch (*selstr) {
/*
Capabilities from the Gopher RFC as of March, 1993:

0   The item is a TextFile Entity.			    ** Implemented
    Item might be an executable shell which outputs the textfile.
    Client should use a TextFile Transaction.

1   The item is a Menu Entity.				    ** Implemented
    Client should use a Menu Transaction. 

2   The information applies to a CSO phone book entity.	    ** Implemented
    Client should talk CSO protocol.			       by client only

3   Signals an error condition.				    ** Implemented

4   Item is a Macintosh file encoded in BINHEX format	    ** Implemented

5   Item is PC-DOS binary file of some sort.		    ** Implemented
    Client gets to decide.

6   Item is a uuencoded file.				    ** Implemented

7   The information applies to a Index Server.		    ** Implemented
    Client should use a FullText Search transaction.

8   The information applies to a Telnet session.	    ** Implemented
    Connect to given host at given port. The name to login
    as at this host is in the selector string.

9   Item is a binary file.				    ** Implemented
    Client must decide what to do with it.

+   The information applies to a duplicated server.	    ** Not Implemented
    The information contained within is a duplicate of 
    the primary server.  The primary server is defined 
    as the last DirEntity that is has a non-plus "Type" 
    field.  The client should use the transaction as 
    defined by the primary server Type field.
    
g   Item is a GIF graphic file.				    ** Implemented

I   Item is some kind of image file.			    ** Implemented
    Client gets to decide.

T   The information applies to a tn3270 based telnet	    ** Implemented
    session. Connect to given host at given port. The 
    name to login as at this host is in the selector string.

Characters '0' through 'Z'  are reserved.  Local experiments 
should use other characters.  Machine-specific extensions are 
not encouraged.  Note that for type 5 or type 9 the client must 
be prepared to read until the connection closes.  There will be 
no period at the end of the file; the contents of these files 
are binary and the client must decide what to do with them based 
perhaps on the .xxx extension.

*/
#ifdef VMS
     case '/':	if (strlen(selstr)!=1)	    /* Some GOPHER Filter or other? */
		    goto old_link;
#endif
     case '\0':
     case '\t':

	  /*** The null capability, so it's not a file, probably wants
	       to talk to a directory server ***/

	  /*** we'll just do a "list" of the root directory, with no user
	       capability.  ***/

	  listdir(sockfd, GDCgetDataDir(Config));
	  LOGGopher(sockfd, "Root Connection");
	  break;

     case A_HTML:
	  /*** An html file.  Turn off html'ing flag but still   ***/
	  /*** processing it as hypertext, i.e., don't use a dot ***/
	  /*** as a terminator.	                                 ***/
	  UsingHTML = FALSE;
	  if (strchr(selstr+1, '/') != NULL) {
	      /*** Convert to VMS pathspecs ***/
	      sprintf(VMSpath, "%c%s", *selstr,
	      		(cp=WWW_to_VMS(selstr+1, *selstr)) ? cp : selstr+1);
	      selstr = VMSpath;
	  }
	  if (printfile(sockfd, selstr+1, 0, -1)==FALSE) {
	    UsingHTML = TRUE;
	    goto no_such_file;
	  }
	  break;

/*
Textfile Entity

TextFile  ::= {TextBlock} Lastline

Note:  Lines beginning with periods must be prepended with an extra 
     period to ensure that the transmission is not terminated early. 
     The client should strip extra periods at the beginning of the line.


TextFile Transaction (Type 0 item)

C: Opens Connection.
S: Accepts connection
C: Sends Selector String.
S: Sends TextFile Entity.

   Connection is closed by either client or server (typically server).

Note:  The client should be prepared for the server closing the
       connection without sending the Lastline.  This allows the
       client to use fingerd servers.
*/
     case A_FILE:
	  /*** It's a generic file capability ***/
     case A_MACHEX:
	  /*** Or a BINHEX'd file ***/
     case A_UUENCODE:
	  /*** Or a UUENCODE'd file ***/
	  if (strchr(selstr+1, '/') != NULL) {
	      /*** Convert to VMS pathspecs ***/
	      sprintf(VMSpath, "%c%s", *selstr,
	      		(cp=WWW_to_VMS(selstr+1, *selstr)) ? cp : selstr+1);
	      selstr = VMSpath;
	  }
	  if (printfile(sockfd, selstr+1, 0, -1)==FALSE) {
	    goto no_such_file;
	  }
	  break;

/*
Menu Entity

Menu      ::= {DirEntity} Lastline.

Menu Transaction  (Type 1 item)

C: Opens Connection
S: Accepts Connection
C: Sends Selector String
S: Sends Menu Entity

   Connection is closed by either client or server (typically server).
*/
     case A_DIRECTORY:
	  /*** It's a directory capability ***/
	  if (strchr(selstr+1, '/') != NULL) {
	      /*** Convert to VMS pathspecs ***/
	      sprintf(VMSpath, "%c%s", *selstr,
	      		(cp=WWW_to_VMS(selstr+1, *selstr)) ? cp : selstr+1);
	      selstr = VMSpath;
	  }
	  listdir(sockfd, selstr+1);
	  break;
#ifdef BUILTIN_SEARCH
     case A_INDEX:
/*
Full-Text Search Transaction (Type 7 item)

Word      ::= {UNASCII - ' '}
BoolOp ::= 'and' | 'or' | 'not' | SPACE
SearchStr ::= Word {{SPACE BoolOp} SPACE Word}

C: Opens Connection.
C: Sends Selector String, Tab, Search String.
S: Sends Menu Entity.

Note:  In absence of 'and', 'or', or 'not' operators, a SPACE is 
       regarded as an implied 'and' operator.  Expression is evaluated
       left to right.  Further, not all search engines or search gateways
       currently implemented have the boolean operators implemented.
*/

	  if (!GDCgetSRCHPort(Config))
	    goto NoSRCHAccess;
#ifdef VMS
         /* Don't allow arbitrary files to be accessed */
	 {
            char *pathstr;
	    char *cl;

	    /*** Get rid of the search string, in case it has a colon ***/
	    pathstr = (char *) malloc(sizeof(char)*strlen(selstr+1)+1);
	    strcpy(pathstr, selstr+1);
	    if (strchr(pathstr,'\t') != 0)
	         *(strchr(pathstr,'\t')) = '\0';

	    /*** Jump over colon-bounded arguments, if present ***/
	    if (*(pathstr) == ':') {
	         if ((cl=strchr(pathstr+1, ':')) == 0) {
		      LOGGopher(sockfd, "Illegal syntax for %s", selstr+1);
		      Abortoutput(sockfd, "Eh? Confusing Request","syntax");
		      free(pathstr);
		      return(FALSE);
		 }
		 cl++;
	    }
	    else
	         cl = pathstr;

	    /*** If a colon is present in the resultant path, validate it ***/
	    if (strchr(cl,':')) {
		char *tmp,*tmp2;
		tmp = (char *) malloc(sizeof(char)*strlen(cl)+1);
		strcpy(tmp, cl);
		if ((tmp2 = strchr(tmp,'\t')) != 0)
		    *tmp2 = '\0';
		if ((tmp2 = strchr(tmp,':')) != 0)
		    *tmp2 = '\0';
		if (0==(tmp2=strrchr(tmp,' ')))
		    tmp2 = cl;
		else
		    tmp2++;
		if (strncasecmp(tmp2, GDCgetDataDir(Config),
				    strcspn(GDCgetDataDir(Config),":"))) {
		    LOGGopher(sockfd, "Denied access for %s", selstr+1);
		    Abortoutput(sockfd, GDCgetBummerMsg(Config),"bummer");
		    free(tmp);
		    return(FALSE);
		}
		free(tmp);
	    }
	    free(pathstr);
	 }
#endif
	  if (!CanAccess(sockfd,ACC_SEARCH)) {
NoSRCHAccess:  LOGGopher(sockfd, "Denied access for %s", selstr+1);
	       Abortoutput(sockfd, GDCgetBummerMsg(Config),"bummer");
	       break;
	  }
	  Do_IndexTrans(sockfd, selstr+1);
	  break;
#endif
     case A_PCBIN:
     case A_UNIXBIN:
     case A_GIF:
     case A_IMAGE:
     case A_SOUND:
/*
Binary file Transaction (Type 9, 5, I, g, s item)

C: Opens Connection.
S: Accepts connection
C: Sends Selector String.
S: Sends a binary file and closes connection when done.
*/
	  /*** It's a binary thingie... ***/
	  if (strchr(selstr+1, '/') != NULL) {
	      /*** Convert to VMS pathspecs ***/
	      sprintf(VMSpath, "%c%s", *selstr,
	      		(cp=WWW_to_VMS(selstr+1, *selstr)) ? cp : selstr+1);
	      selstr = VMSpath;
	  }
	  echosound(sockfd, selstr+1);
	  break;

#ifdef GOPHER_MAILSPOOL
     case A_MAILSPOOL:
	  /*** This is an internal identifier ***/
	  /*** The m paired with an Objtype of 1 makes a mail spool file
	       into a directory.
	  ***/
	  if (!CanAccess(sockfd,ACC_BROWSE)) {
	       LOGGopher(sockfd, "Denied access for %s", selstr+1);
	       Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
	       break;
	  }
	  process_mailfile(sockfd, selstr + 1);

	  /** Log it **/
	  LOGGopher(sockfd, "retrieved maildir %s", selstr+1);
	  break;
#endif
     case A_RANGE:
	  /*** This is an internal identifier ***/
	  /*** The R defines a range  ****/
	  /*** The format is R<startbyte>-<endbyte>-<filename> **/
     {
	  int startbyte, endbyte;
	  char *oldcp;
	  FILE *SideFile;
	  GopherStruct *gs;

	  cp = strchr(selstr+1, '-');
	  
	  if (cp == NULL) {
	       LOGGopher(sockfd, "missing '-' after <startbyte>");
	       Abortoutput(sockfd, "Range specifier error", "range");
	       break;
	  }
	  
	  *cp = '\0';
	  startbyte = atoi(selstr+1);
	  oldcp = cp+1;

	  cp = strchr(oldcp, '-');
	  
	  if (cp == NULL) {
	       LOGGopher(sockfd, "missing '-' after <endbyte>");
	       Abortoutput(sockfd, "Range specifier error", "range");
	       break;
	  }

	  *cp = '\0';
	  endbyte = atoi(oldcp);
	  *cp = A_FILE;
	  oldcp = cp + 1;
	  if (strchr(oldcp, '/') != NULL) {
	      /*** Convert to VMS pathspecs ***/
	      char *cp1;
	      strcpy(VMSpath, (cp1=WWW_to_VMS(oldcp, A_FILE)) ? cp1 : oldcp);
	      oldcp = VMSpath;
	  }
	  if (DEBUG)
	       printf("Start: %d, End: %d  File: %s\n", startbyte, endbyte, oldcp);

	  if (printfile(sockfd, oldcp, startbyte, endbyte)==FALSE) {
	    goto no_such_file;
	  }
	  break;
     }

     case A_FTP:
	  if (!GDCgetFTPPort(Config))
	    goto NoFTPAccess;
	  if (!CanAccess(sockfd,ACC_BROWSE)) {
NoFTPAccess:   LOGGopher(sockfd, "Denied access for %s", selstr);
	       Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
	       break;
	  }

	  if (strncmp(selstr, "ftp:",4)==0){
	       LOGGopher(sockfd, "retrieved %s", selstr);
	       SendFtpQuery(sockfd, selstr+4);
	       break;
	  }
	  break;

     case A_EVENT:
	  if (!GDCgetEXECPort(Config))
	    goto NoEXECAccess;
	  if (!CanAccess(sockfd,ACC_BROWSE)) {
NoEXECAccess:  LOGGopher(sockfd, "Denied access for %s", selstr);
	       Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
	       break;
	  }

	  if (strncmp(selstr, "exec:", 5)==0) {
	  /*
		arguments, if any,  are between a colon at selstr+4 and 
		another colon, at or beyond selstr+5.  Search from the end 
		for another colon    
	  */
	       char *args, *command;
	       
	       command = strrchr(selstr + 5, ':');
	       if (command==NULL)
	  /* no second colon, so it's a bad selstr */
		    break;
#ifdef VMS
	       {
		    char *c2;
		/*
		    command is pointing to the last colon; it could be part of 
		    "GOPHER_ROOTx:", or it could be the other arg boundary (if 
		    the device was defaulted), so we search backward for 
		    another colon, between the first one and this one
		*/
		    *command = '\0';
		    c2 = strrchr(selstr + 5, ':');
		    *command = ':';
		/* 
		    If we did find another colon, and its followed by a 
		    validated path, that's the colon which terminates the
		    arguments, so point command there (otherwise, leave
		    command pointing to the last colon, because the device
		    was defaulted, and that *is* an arg boundary).
		*/
		    if (c2 != NULL && Validate_Filespec(c2+1) != NULL)
			 command = c2;
	       }
#endif
	       if (*(selstr+4) == ':' && *(selstr+5) == ':')
		    args = NULL;
	       else
		    args = selstr+5;

	       *command = '\0';
	       command++;
	       
	       EXECargs = args;

	       if (strchr(command, '/') != NULL) {
	           /*** Convert to VMS pathspecs ***/
	           strcpy(VMSpath,
		   	  (cp=WWW_to_VMS(command, A_FILE)) ? cp : command);
		   command = VMSpath;
	       }
	       if (printfile(sockfd, command, 0, -1)==FALSE) {
		    goto no_such_file;
	       }
	  }
	  break;

     case A_WAIS:
     {
	  if (strncmp(selstr, "waissrc:", 8) == 0) {
	       if (!CanAccess(sockfd,ACC_SEARCH)) {
		    LOGGopher(sockfd, "Denied access for %s", selstr);
		    Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
		    break;
	       }

	       SearchRemoteWAIS(sockfd, selstr+8);
	       break;
	  }
	  else if (strncmp(selstr, "waisdocid:", 10) == 0) {
	       if (!CanAccess(sockfd,ACC_BROWSE)) {
		    LOGGopher(sockfd, "Denied access for %s", selstr);
		    Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
		    break;
	       }
	       Fetchdocid(sockfd, selstr+10);
	       break;
	  }
     }

     default:
     old_link:
	  /*** Hmmm, must be an old link... Let's see if it exists ***/

	  switch (isadir(selstr)) {
	  case -1:
	  no_such_file:
	       /* no such file */
#ifdef VMS
	       if (vaxc$errno || vaxc$errno_stv)
		    LOGGopher(sockfd, "'%s' does not exist (%s%s%s)", selstr,
				    strerror(EVMSERR,vaxc$errno),
				    vaxc$errno_stv?"/":"",
				    vaxc$errno_stv?
					strerror(EVMSERR,vaxc$errno_stv):"");
		else
#endif
	       LOGGopher(sockfd, "'%s' does not exist", selstr);
	       selstr = NoSuchFile;
	       goto print_old_file;
	  case 0:
	       /* it's a file */
	       memmove(selstr+1,selstr,strlen(selstr));
	       ZapCRLF(selstr);
	       *selstr = A_FILE;
	       selstr++;
	  print_old_file:
	       if (printfile(sockfd, selstr, 0, -1)==FALSE) {
		    if (selstr != NoSuchFile)
			goto no_such_file;
		    else {
			writestring(sockfd, "- Cannot access file\r\n.\r\n");
			LOGGopher(sockfd, "server error file %s missing",
					    selstr);
			break;
		    }
	       }
	       break;
	  case 1:
	       /* it's a directory */
	       listdir(sockfd, selstr);
	       break;
	  }
     }

     return(FALSE);
}

/*
 * Returns true (1) for a directory
 *         false (0) for a file
 *         -1 for anything else
 */
int
isadir(char *path)
{
     struct stat buf;
     int result;

     result = stat(path, &buf);

     if (result != 0)
	  return(-1);
     
#ifdef BROKENDIRS

#define S_ISDIR(m)      (((m)&S_IFMT) == S_IFDIR)
#define S_ISREG(m)      (((m)&S_IFMT) == S_IFREG)

#endif

     if (S_ISDIR(buf.st_mode))
	  return(1);
     else if (S_ISREG(buf.st_mode))
	  return(0);
     else
	  return(-1);
}

/*
 * Returns -1 on failure, size in bytes of file on sucess
 *			    as well as timestamp of last access
 */
int
file_stats(char *path, unsigned *tstamp)
{
     struct stat buf;
     int result;

     result = stat(path, &buf);

     if (result != 0)
	  return(-1);

     *tstamp = buf.st_mtime;
     return(buf.st_size);
}

/*
 * This function tries to find out what type of file a pathname is.
 * It then fills in the VAR type variables ObjType & ServerPath with
 * corresponding info.
 */
void
Getfiletypes(char *newpath, char *filename, char *ObjType, char **ServerPath)
{
     boolean dirresult;
     int Zefilefd;
     static char Zebuf[256];
     char *cp;
     static char Selstr[512];

     
     if (ServerPath != NULL)	     /* Don't overwrite existing path if any */
	  *ServerPath = Selstr; 


     dirresult = isadir(filename);

     if (dirresult == -1) {             /** Symlink or Special **/
	  *ObjType = A_ERROR;
	  return;
     }

     if (dirresult == 1) {
	  *ObjType = *Selstr = A_DIRECTORY;
	  strcpy(Selstr +1, newpath);
#ifdef VMS
	  *(strrchr(Selstr +1,'.')) = '\0';
	  *(strrchr(Selstr +1,']')) = '.';
	  strcat(Selstr +1,"]");
#endif
	  return;
     }
		 
     
     else {	      /** Some kind of data file.... */

	  /*** The default is a generic text file ***/

	  *ObjType = *Selstr = A_FILE;
	  strcpy(Selstr + 1, newpath);

	  /*** Test and see if the thing exists... and is readable ***/
	  
	  if ((Zefilefd = open(filename, O_RDONLY)) < 0) {
	       *ObjType = A_ERROR;
	       return;
	  }
	  
	  bzero(Zebuf, sizeof(Zebuf));
	  read(Zefilefd, Zebuf, sizeof(Zebuf));
	  close(Zefilefd);
	  
	  /*** Check the first few bytes for sound data ***/
	  
	  cp = Zebuf;

	  if (strncasecmp(cp, ".snd", 4)==0) {
	       *ObjType = *Selstr = A_SOUND;
	       strcpy(Selstr+1, newpath);
	  }
#ifdef GOPHER_MAILSPOOL
	  /*** Check and see if it's mailbox data ***/
	  
	  if (is_mail_from_line(Zebuf)==0) {
	       *ObjType = A_DIRECTORY;
	       *Selstr = A_MAILSPOOL;
	       strcpy(Selstr+1, newpath);
	  }
#endif	  

	  /*** Check for uuencoding data ***/

	  if ((strncmp(cp,"begin",5)==0) || (strncmp(cp,"table",5)==0))  {
	       *ObjType = *Selstr = A_UUENCODE;
	       strcpy(Selstr+1, newpath);
	  }
	  
	  /*** Check for GIF magic code ***/
	  
	  if (strncasecmp(cp, "GIF", 3) == 0) {
	       *ObjType = *Selstr = A_GIF;
 	       strcpy(Selstr + 1, newpath);
 	  }

	  /*** Okay, now let's check for the stuff from gopherd.conf files ***/
     {
	  char Gtype, *prefix;

     	  if (GDCExtension(Config, filename, &Gtype, &prefix)) {
	       *ObjType = Gtype;
	       strcpy(Selstr, prefix);
	       strcpy(Selstr+strlen(prefix), newpath);
	  }
     }
			   

     }

}

/*
** This function lists out what is in a particular directory.
** it also outputs the contents of link files.
**
** Ack is this ugly.
*/
void
listdir(int sockfd, char *pathname)
{
     char   /* DIR */	   *ZeDir;
     char                  filename[256];
     static char           newpath[512];
     static GopherStruct   *Gopherp = NULL;
     char	           *cachefile;
     static ExtArray	   *IgnoreHere = NULL;
     static String	   *DName = NULL;
     static SiteArray	   *AccessHere = NULL;
     static Accesslevel	   Defaccess = ACC_FULL;
     int		   Do_Sort, Ignore_All = FALSE;
#ifdef VMS
     char		   *dp, *cp;
#else
     struct dirent	   *dp;
#endif
     char		   buf[1024];
     boolean		   LCLIgnore(ExtArray *Ignore, char *filename);
     void		   LCLfromLink(FILE *linkfd, ExtArray **IgnoreHere, 
					String **DName, SiteArray **AccessHere, 
 					Accesslevel *Defaccess, 
 					char *filename, int *Do_Sort,
 					int *Ignore_All);
     Do_Sort = GDCgetSortDir(Config);
     /*** Make our gopherobj ****/
     if (Gopherp == NULL)
	  Gopherp = GSnew();
     if (IgnoreHere != NULL) {
	ExtArrDestroy(IgnoreHere);
	IgnoreHere = NULL;
     }
     if (DName != NULL) {
	STRdestroy(DName);
	DName = NULL;
     }
     if (AccessHere != NULL) {
	SiteArrDestroy(AccessHere);
	AccessHere = NULL;
	Defaccess = ACC_FULL;
     }
#ifdef VMS
     /* Don't accept anything but valid VMS directory specification */
     
     if (Validate_Filespec(pathname)==NULL) {
	LOGGopher(sockfd, "Illegal syntax for %s", pathname);
        if (UsingHTML) {
	     writestring(sockfd, "Eh? Confusing Request\n");
	     printfile(sockfd, SyntaxErr+1, 0, -1);
	}
	else
	     Abortoutput(sockfd, "Eh? Confusing Request","syntax");
	return;
     }
     /* Don't allow arbitrary files to be accessed */
     if (strchr(pathname,':'))
	if (strncasecmp(pathname, GDCgetDataDir(Config),
			    strcspn(GDCgetDataDir(Config),":"))) {
	    LOGGopher(sockfd, "Denied access for %s", pathname);
            if (UsingHTML)
	         printfile(sockfd, BummerMsg+1, 0, -1);
	    else
	         Abortoutput(sockfd, GDCgetBummerMsg(Config),"bummer");
	    return;
	}
#endif

     if (chdir(pathname)<0) {
	  LOGGopher(sockfd,"chdir(\"%s\") error: %s",pathname,
						STRerror(errno));
          if (UsingHTML)
	       printfile(sockfd, BaddirMsg+1, 0, -1);
	  else
	       Abortoutput(sockfd, "Cannot access that directory", "baddir");
	  return;
     }

     if (!CanAccess(sockfd,ACC_BROWSE)) {
     cant_browse:
	  LOGGopher(sockfd, "Denied access for %s", pathname);
          if (UsingHTML)
	       printfile(sockfd, BummerMsg+1, 0, -1);
	  else
	       Abortoutput(sockfd,  GDCgetBummerMsg(Config), "bummer");
	  return;
     }

     SortDir = GDnew(64);

     if ((ZeDir = ropendir(pathname)) == NULL) {
	  LOGGopher(sockfd,"chdir(\"%s\") error: %s",pathname,
						STRerror(errno));
          if (UsingHTML)
	       printfile(sockfd, BaddirMsg+1, 0, -1);
	  else
	       Abortoutput(sockfd, "Cannot access that directory", "baddir");
	  GDdestroy(SortDir);
	  return;
     }

     for (dp = readdir(ZeDir); dp != NULL; dp = readdir(ZeDir)) {

          strcpy(newpath, pathname);
#ifdef VMS
          /* force names lowercase */
          for(cp = dp; *cp; cp++)
               *cp = _tolower(*cp);
          if (*(cp-1) == 'z')
	       *(cp-1) = 'Z';
          strcat(newpath, dp);
	  strcpy(filename, dp);
#else
          strcat(newpath, dp/*->d_name*/);
	  strcpy(filename, dp/*->d_name*/);
#endif
	  if ((strncasecmp(filename,GDCgetLinkPrefix(Config),
		    	strlen(GDCgetLinkPrefix(Config))) == 0) &&
	      isadir(filename)==0  &&
	      strncasecmp(filename, ".cache", 6) !=0) {
	       /*** This is a link file, let's process it ***/
	       FILE *linkfd;

	       linkfd = fopen(filename, "r");

	       if (linkfd != NULL) {
		    LCLfromLink(linkfd, &IgnoreHere, &DName, &AccessHere,
 					&Defaccess, filename, &Do_Sort,
 					&Ignore_All);
		    GDfromLink(SortDir, linkfd, GDCgetHostname(Config),
				    GDCgetPort(Config), filename, 
					sockfd, ACC_BROWSE);
		    fclose(linkfd);
		    if (!LCLCanAccess(sockfd, AccessHere, Defaccess,
					    ACC_BROWSE))
			goto cant_browse;
	       }
	       
	  }
	  if ((strncasecmp(filename,GDCgetLinkPrefix(Config),
		    	strlen(GDCgetLinkPrefix(Config))) != 0)
		&& (strncasecmp(filename,GDCgetHiddenPrefix(Config),
		    	strlen(GDCgetHiddenPrefix(Config))) != 0)
 			    && !Ignore_All
			    && !LCLIgnore(IgnoreHere, filename)
			    && !GDCignore(Config, filename)) {
		GSinit(Gopherp);
		GSsetHost(Gopherp, GDCgetHostname(Config));
		GSsetPort(Gopherp, GDCgetPort(Config));
		AddFiletoDir(sockfd, Gopherp, SortDir, filename, newpath, 
				    DName);
	  }
     }

     if (GDgetNumitems(SortDir)) {
	GDaddDateNsize(SortDir);
	if (Do_Sort)
	    GDsort(SortDir);
	if (UsingHTML)
	    GDtoNetHTML(SortDir, sockfd);
	else {
	    GDtoNet(SortDir, sockfd);
	    writestring(sockfd, ".\r\n");
	}
        /** Log it **/
	LOGGopher(sockfd, "retrieved directory %s", pathname);
     }
     GDdestroy(SortDir);
     if (IgnoreHere != NULL) {
	ExtArrDestroy(IgnoreHere);
	IgnoreHere = NULL;
     }
     if (DName != NULL) {
	STRdestroy(DName);
	DName = NULL;
     }
     if (AccessHere != NULL) {
	SiteArrDestroy(AccessHere);
	AccessHere = NULL;
	Defaccess = ACC_FULL;
     }
}

/*
 *  This processes a single filename, adding it to the sort directory
 */
AddFiletoDir(int sockfd, GopherStruct *gs, GopherDirObj *gd,
		char *filename, char *newpath, String *DName)
{

    FILE   *SideFile;
#ifdef VMS
    char   VMS_dir_title[256];
#endif
    char   Typep;
    char   *Pathp;

    Typep = '\0';
    Pathp = NULL;
	       

    Getfiletypes(newpath, filename, &Typep, &Pathp);
	       
    if (Typep == A_ERROR)
	return;
	       
    GSsetType(gs, Typep);
    GSsetPath(gs, Pathp);

#ifdef GOPHER_ZCOMPRESS
    if (GSgetTitle(gs) == NULL) {
		    /*** Check to see if we have a compressed file ***/
		    
	if (strcmp(filename + strlen(filename) -2, ".Z") ==0 &&
		strcmp(filename + strlen(filename) -6, ".tar.Z") != 0)
	    filename[strlen(filename) - 2] = '\0';
    }
#endif
    if (SideFile = Build_Lookaside(newpath, filename, gs))
	Process_Side(SideFile, gs, GDCgetHostname(Config),
					GDCgetPort(Config), filename);
    switch(GSgetType(gs)) {
    case A_DIRECTORY:	    /*** It's a directory ***/
    case A_INDEX:	    /*** It's an index ***/
    case A_FTP:		    /*** ftp link ***/
    case A_EVENT:	    /*** exec link ***/
    case A_HTML:	    /*** www link ***/
    case A_WAIS:	    /*** wais or whois link ***/
		break;
    default:
	    if (GSgetTitle(gs) == NULL) {
		if (DName != NULL)
		    GSsetTitle(gs, STRget(DName));
		else
		    if (*(GDCgetDName(Config)) != '\0')
			GSsetTitle(gs, GDCgetDName(Config));
	    }
    }
#ifdef VMS  /* This strips the '.DIR' from default directory titles */
    if (GSgetTitle(gs) == NULL) {
         if (GSgetType(gs) == A_DIRECTORY) {
              strncpy(VMS_dir_title, filename, strlen(filename)-4);
              VMS_dir_title[strlen(filename)-4] = '\0';
	      GSsetTitle(gs, VMS_dir_title);
         }
         else
	      GSsetTitle(gs, filename);
    }
#else
    if (GSgetTitle(gs) == NULL)
        GSsetTitle(gs, filename);
#endif
    switch(GSgetType(gs)) {
    case A_WAIS:	if (strncmp(GSgetPath(gs),"aisdocid:",9)==0)
			    if (!GScanAccess(sockfd, gs, ACC_BROWSE))
				return;
					/* Note: Wais *searches* fall thru */
    case A_INDEX:	if (!GScanAccess(sockfd, gs, ACC_SEARCH))
			    return;
			break;
    case A_EVENT:
    case A_FILE:
    case A_SOUND:
    case A_MACHEX:
    case A_PCBIN:
    case A_UUENCODE:
    case A_RANGE:
    case A_UNIXBIN:
    case A_GIF:
    case A_HTML:
    case A_IMAGE:	if (!GScanAccess(sockfd, gs, ACC_READ))
			    return;
			if (GSgetType(gs) != A_EVENT)
			    break;
				    /* Note: non-EXEC's fall thru */
    case A_MAILSPOOL:
    case A_FTP:
    case A_DIRECTORY:	if (!GScanAccess(sockfd, gs, ACC_BROWSE))
			    return;
    }

#ifdef dlpath
    /* Process a "dl" description if there is one! */

    dlpath[0] = '.';
    dlpath[1] = '\0';
    dlout = getdesc(NULL,dlpath,filename,0);

    if (DEBUG)
	printf("dl: %s %s %s\n", dlpath, filename, dlout);
    if (dlout != NULL) {
	GSsetTitle(gs, dlout);
    }
#endif

/*** Add the entry to the directory ***/

    GDaddGS(gd, gs);
    GSinit(gs);
}

/*
 *  This pre-reads a link file and picks off directives prior to the first
 *  link tuple which are to apply to this directory only.
 *	Ignore=, DName= and Access= are defined.
 */
void
LCLfromLink(FILE *linkfd, ExtArray **IgnoreHere, String **DName, 
		SiteArray **AccessHere, Accesslevel *Defaccess, char *filename,
		int *Do_Sort, int *Ignore_All)
{
    char    buf[1024];
#ifdef VMS
    int posit;
#else
    fpos_t  posit;
#endif

#ifdef VMS
    while((posit=ftell(linkfd)) != EOF && fgets(buf,1024,linkfd)) {
#else
    while(fgetpos(linkfd,&posit),fgets(buf,1024,linkfd)) {
#endif
	if (buf[0] == '#')
	    continue;
	ZapCRLF(buf);
	if (strlen(skip_whitespace(buf))==0)
	    continue;
        if (DEBUG)
	    printf("%s: %s\n",filename, buf);
	if (strncasecmp(buf, "Ignore=", 7)==0) {
	    if (*IgnoreHere == NULL)
		*IgnoreHere = ExtArrayNew();
	    ExtAdd(*IgnoreHere, A_ERROR, "", "", buf+7);
	    continue;
	}
	if (strncasecmp(buf, "Access=", 7)==0) {
	    int moo;
	    if (*AccessHere == NULL)
		*AccessHere = SiteArrayNew();
	    SiteProcessLine(*AccessHere, buf+7, *Defaccess);
	    moo = SiteAccess(*AccessHere, "default");
	    if (moo != ACC_UNKNOWN)
		*Defaccess = moo;
	    continue;
	}
	if (strncasecmp(buf, "DName=", 6)==0) {
	    if (*DName == NULL)
		STRinit(*DName = STRnew());
	    STRset(*DName, buf+6);
	    continue;
	}
	if (strncasecmp(buf, "SortDir=", 8)==0) {
	    if (strncasecmp(buf+8,"TRUE",4)==0)
		*Do_Sort = TRUE;
            else
		*Do_Sort = FALSE;
 	    continue;
 	}
 	if (strncasecmp(buf, "IgnoreAll=", 10)==0) {
 	    if (strncasecmp(buf+10,"TRUE",4)==0)
 		*Ignore_All = TRUE;
             else
 		*Ignore_All = FALSE;
	    continue;
	}
	/* Hit non-comment, non-whitespace, line that doesn't match
	    any of our prefix commands.  Must be the 1st link tuple; that's
	    EOF for us... */
	break;
     }
#ifdef VMS
     fseek(linkfd,posit,0);
#else
     fsetpos(linkfd,&posit);
#endif
     return;
}

/*
 * This tests to see if a local (.links) ignore specification matches the
 * specified filename.  This is just like GDCignore except it uses a
 * different extension array, and we need to check & see if that list exists.
 */
boolean
LCLIgnore(ExtArray *Ignore, char *filename)
{
    char objtype, *gplustype, **prefix;

    if (Ignore == NULL)
	return(FALSE);
	    ExtGet(Ignore, filename, &objtype, &gplustype, &prefix);
    if (objtype == A_ERROR)
	return(TRUE);
    else
	return(FALSE);
}

/*
 * This tests to see if a local (.links) access specification matches the
 * current client's address, and if so can this client access.
 */
boolean
LCLCanAccess(int sockfd, SiteArray *Access, Accesslevel DefAccess, int access)
{
     boolean		test;

     if (Access == NULL)
	return(TRUE);

     if (DEBUG)
          printf("Testing %s/%s for access\n", CurrentPeerName, CurrentPeerIP);

     switch(access)
     {
     case ACC_SEARCH:
	test = SiteArrCanSearch(Access, CurrentPeerName, CurrentPeerIP);
	break;
     case ACC_READ:
        test = SiteArrCanRead(Access, CurrentPeerName, CurrentPeerIP);
	break;
     case ACC_BROWSE:
        test = SiteArrCanBrowse(Access, CurrentPeerName, CurrentPeerIP);
	break;
     default:
        if ((DefAccess & access) == access)
	    return(TRUE);
     }
     if (test != ACC_UNKNOWN)
	  return(test);
     
     if ((DefAccess & access) == access)
	  return(TRUE);
     else
	  return(FALSE);
}

/*
 * This produces a lookaside filename given a path and a filename.
 *
 *  For VMS, the application ACE's (if any) are tested to locate any
 *  GOPHER_ACE entries; if present, these are processed, and NULL is 
 *  returned to indicate no lookaside file is to be processed, even if
 *  one exists.
 */
FILE *
Build_Lookaside(char *path, char *file, GopherStruct *gs)
{
    FILE    *SideFile;
    char    sidename[256];

#ifdef VMS
    if (ACL_Lookaside(path, gs, GDCgetHostname(Config), 
			GDCgetPort(Config)))
	return(NULL);	
    if (file==NULL) {
	file = path;
	path = "[]";
    }
    strcpy(sidename, path);
    *(strchr(sidename, ']')) = '\0';
    strcat(sidename, ".");
    strcat(sidename, GDCgetLookAside(Config));
    strcat(sidename, "]");
    strcat(sidename, file);
#else
    if (newpath[strlen(newpath)-1] != '/')
	strcat(newpath, "/");
    strcat(newpath, file);
    strcpy(sidename, "./.cap/");
    strcat(sidename, file);
#endif
    if ((SideFile = fopen(sidename, "r"))!=0) {
	if (DEBUG == TRUE)
	    printf("Side file name: %s\n", sidename);
    }
    return(SideFile);
}

#ifdef VMS
/*
 *  This tests for Application ACE entries in the file's Access Control List
 *  which match the GOPHER_ACE value.  If any, store them into the GopherStruct
 *  supplied and return TRUE; otherwise return FALSE.
 */
#include <atrdef.h>
#include <acedef.h>
int
ACL_Lookaside(char *file, GopherStruct *Gopherp, char *host, int port)
{
    int	    ACL_present=FALSE;		/* Status			    */
    char    *acl_ptr;			/* Pointer to acl string	    */
    char    *gopher$;			/* Pointer to GOPHER character data */
    int	    g;				/* Length of GOPHER character data  */
    struct  acedef 
	    *ace$;			/* Pointer to actual ACE	    */
    int	    status;			/* system status		    */
    int	    acl_length;			/* ACL return length		    */
    char    acl_buffer[ATR$S_READACL];	/* ACL work buffer		    */
    struct dsc$descriptor_s 
	    acl_entry = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};
    struct FAB 
	    acl_fab;     
    struct XABPRO 
	    acl_xab;   

    acl_fab = cc$rms_fab;           
    acl_xab = cc$rms_xabpro;         
    acl_fab.fab$l_fna = file;
    acl_fab.fab$b_fns = strlen(acl_fab.fab$l_fna);
    if (((status = SYS$OPEN(&acl_fab, 0, 0)) &1) != 1) 
	return(ACL_present);
	/*
	    Connect the XAB to the FAB block and perform an initial $DISPLAY.
	*/
    acl_fab.fab$l_xab = (char *) &acl_xab;          
    acl_xab.xab$l_aclbuf = acl_buffer;      
    acl_xab.xab$w_aclsiz = ATR$S_READACL; 
    acl_xab.xab$l_aclctx = 0;
    if (!(1 & sys$display(&acl_fab, 0, 0)))
	goto close_fab;
    /*
	While we actually have an ACL and the ACL lookup was correct, we
	run through the ACL list within the ACL buffer and format each ACE.
	Since the buffer is relatively small, keep '$DISPLAY'ing the
	file until there is no more ACL entries to find.  The first $DISPLAY
	was done when the file was $OPENed, the next $DISPLAY reads XAB$L_ACLCXT
	to get subsequent ACL entries for the buffer.
    */
    while ((acl_xab.xab$w_acllen != 0)) {
	acl_ptr = acl_buffer;               /* Beginning of the ACLs */
        while((*acl_ptr != 0) && ((acl_ptr - acl_buffer) < ATR$S_READACL))
        {               /* The first byte is the size of the ACL */
	    ace$ = (struct acedef *)acl_ptr;
	    if ((ace$->ace$b_type==ACE$C_INFO) &&
		(strncmp((char *)&(ace$->ace$l_access),
		    GOPHER_ACE,strlen(GOPHER_ACE))==0)) {
		g = ace$->ace$b_size - 4 - strlen(GOPHER_ACE);
		gopher$ = (char *)malloc(sizeof(char)*g+1);
		memcpy(gopher$,
			((char *)&(ace$->ace$l_access))+strlen(GOPHER_ACE) ,g);
		*(gopher$+g) = '\0';
		Process_Sideline(gopher$, Gopherp, host, port, "(ACL)");
		free(gopher$);
		ACL_present = TRUE;
	    }
	    acl_ptr = acl_ptr + *acl_ptr;   /* Get the next ACL entry */
        }
	bzero(acl_buffer, ATR$S_READACL);
	status = sys$display(&acl_fab, 0, 0);/* Get the next ACL block */
	if (!(status&1))
	    goto close_fab;
	if (!(acl_xab.xab$l_aclsts&1))
	    break;
	}
close_fab:
    sys$close(&acl_fab,0,0);
    if (ACL_present && (GSgetPort(Gopherp)==0))
	if (GSgetPath(Gopherp))
	    switch(*GSgetPath(Gopherp))
	    {
	  case A_INDEX:	GSsetPort(Gopherp, GDCgetSRCHPort(Config)); break;
	  case A_FTP:	GSsetPort(Gopherp, GDCgetFTPPort(Config));  break;
	  case A_EVENT:	GSsetPort(Gopherp, GDCgetEXECPort(Config)); break;
	  default:	GSsetPort(Gopherp,port);
	    }
	else
	    GSsetPort(Gopherp,port);
    return(ACL_present);
}
#endif

/*
 * This processes a file containing any subset of Type=, Name=, Path=, Port=,
 * Host=, Numb=, Hidden or Access=, and overrides the supplied GopherStruct
 * entries.
 *
 * The caller may choose to initialise the pointers - so we don't
 * touch them unless we find an over-ride.
 */
Process_Side(FILE *sidefile, GopherStruct *Gopherp, char *host, int port,
			char *filename)
{
     char inputline[MAXLINE];
     char *cp;

     inputline[0] = '\0';

     for (;;) {
	  for (;;) {
	       cp = fgets(inputline, 1024, sidefile);
	       if (inputline[0] != '#' || cp == NULL)
		    break;
	  }
	  
	  /*** Test for EOF ***/
	  if (cp==NULL)
	       break;
	  
	  ZapCRLF(inputline);  /* should zap tabs as well! */
#ifdef VMS
	  Continuation(inputline,sidefile,1024,'-');
#endif
	  Process_Sideline(inputline, Gopherp, host, port, filename);
     }
     fclose(sidefile);
     if (GSgetPort(Gopherp)==0)
	if (GSgetPath(Gopherp))
	    switch(*GSgetPath(Gopherp))
	    {
	  case A_INDEX:	GSsetPort(Gopherp, GDCgetSRCHPort(Config)); break;
	  case A_FTP:	GSsetPort(Gopherp, GDCgetFTPPort(Config));  break;
	  case A_EVENT:	GSsetPort(Gopherp, GDCgetEXECPort(Config)); break;
	  default:	GSsetPort(Gopherp,port);
	    }
	else
	    GSsetPort(Gopherp,port);
}

/*
 * This processes a line containing any of Type=, Name=, Path=, Port=,
 * Host=, Numb=, Hidden or Access=, and overrides the supplied GopherStruct
 * entries.
 */
Process_Sideline(char *inputline, GopherStruct *Gopherp, char *host, int port,
			char *filename)
{
    if (DEBUG)
	printf("%s: %s\n", filename, inputline);
    
    /*** Test for the various field values. **/
	  
    if (strncasecmp(inputline, GS_TYPE, strlen(GS_TYPE))==0) {
	GSsetType(Gopherp, inputline[strlen(GS_TYPE)]);
	if (GSgetPath(Gopherp)!=NULL) {
	    /*** Might as well set the path too... ***/
	    if (inputline[strlen(GS_TYPE)] == A_INDEX) {
		*(GSgetPath(Gopherp)) = A_INDEX;
	    }
	    if (inputline[strlen(GS_TYPE)] == A_UNIXBIN) {
		*(GSgetPath(Gopherp)) = A_UNIXBIN;
	    }
	}
    }
    else 
    if (strncasecmp(inputline, GS_NAME, strlen(GS_NAME))==0) {
	GSsetTitle(Gopherp, inputline+strlen(GS_NAME));
    }
    else 
    if (strncasecmp(inputline, GS_HOST, strlen(GS_HOST))==0) {
	if ((inputline[strlen(GS_HOST)] == '+' 
			|| inputline[strlen(GS_HOST)] == '*') 
			    && inputline[strlen(GS_HOST)+1] == '\0')
	    GSsetHost(Gopherp, host);
	else
	    GSsetHost(Gopherp, inputline+strlen(GS_HOST));
    }
    else 
    if (strncasecmp(inputline, GS_PORT, strlen(GS_PORT))==0) {
	if ((inputline[strlen(GS_PORT)] == '+' 
			|| inputline[strlen(GS_PORT)] == '*') 
			    && inputline[strlen(GS_PORT)+1] == '\0')
	    GSsetPort(Gopherp, 0);
	else
	    GSsetPort(Gopherp, atoi(inputline+strlen(GS_PORT)));
    }
    else 
    if (strncasecmp(inputline, GS_PATH, strlen(GS_PATH))==0) {
	GSsetPath(Gopherp, inputline+strlen(GS_PATH));
    }
    else 
    if (strncasecmp(inputline, GS_NUMB, strlen(GS_NUMB))==0) {
	GSsetNum(Gopherp, atoi(inputline+strlen(GS_NUMB)));
    }
    else
    if (strncasecmp(inputline, GS_HDDN, strlen(GS_HDDN))==0) {
	GSsetNum(Gopherp, -99);
    }
    else
    if (strncasecmp(inputline, GS_ACCS, strlen(GS_ACCS)) == 0) {
	if (GSgetAccess(Gopherp) == NULL)
	    GSsetAccess(Gopherp, SiteArrayNew());
	GSsetAccessSite(Gopherp, inputline+strlen(GS_ACCS));
	GSsetDefAcc(Gopherp, GSgetSiteAccess(Gopherp, "default"));
	if (GSgetDefAcc(Gopherp) == ACC_UNKNOWN)
	    GSsetDefAcc(Gopherp, ACC_FULL);
    }
    else 
    if (strncasecmp(inputline, GS_HEAD, strlen(GS_HEAD))==0) {
	GSsetHeader(Gopherp, inputline+strlen(GS_HEAD));
    }
    else 
    if (strncasecmp(inputline, GS_FOOT, strlen(GS_FOOT))==0) {
	GSsetFooter(Gopherp, inputline+strlen(GS_FOOT));
    }
    else 
    if (strncasecmp(inputline, GS_RHEAD, strlen(GS_RHEAD))==0) {
	GSsetRHeader(Gopherp, inputline+strlen(GS_RHEAD));
    }
    else 
    if (strncasecmp(inputline, GS_RFOOT, strlen(GS_RFOOT))==0) {
	GSsetRFooter(Gopherp, inputline+strlen(GS_RFOOT));
    }
}

/*
** This function opens the specified file, starts a zcat if needed,
** and barfs the file across the socket.
**
** It now also checks and sees if access is allowed
**
**
*/

int
printfile(int sockfd, char *pathname, int startbyte, int endbyte)
{
     FILE *ZeFile;
     FILE *SideFile;
     char inputline[512];
     GopherStruct *gs = NULL;
     char *cp;
     int WasThere;
#define	FromDoc	"This is a section of the document "

     gs = GSnew();
     GSsetTitle(gs,pathname);
     GSsetPath(gs,pathname-1);
     GSsetType(gs,*(pathname-1));

#ifdef VMS
     /* Don't accept anything but valid VMS directory specification */
     
     if (Validate_Filespec(pathname)==NULL) {
	/** Don't log if we looped back to here **/
        if (pathname != NoSuchFile) {
	     LOGGopher(sockfd, "Invalid Filespec for %s", pathname);
	     pathname = NoSuchFile;
	}
	pathname++;
	startbyte = 0;
	endbyte = -1;
	GSdestroy(gs);
	gs = NULL;
	goto print_file;
     }
     /* Don't allow arbitrary files to be accessed */
     if (strchr(pathname,':'))
	if (strncasecmp(pathname, GDCgetDataDir(Config),
				strcspn(GDCgetDataDir(Config),":"))) {
	    LOGGopher(sockfd, "Denied access for %s", pathname);
	    pathname = BummerMsg;
	    pathname++;
	    startbyte = 0;
	    endbyte = -1;
	    GSdestroy(gs);
	    gs = NULL;
	    goto print_file;
	}
#endif
     /*** Check and see if the peer has permissions to read files ***/

     cp = strchr(pathname,']');
     if (SideFile = Build_Lookaside(pathname, (cp)?cp+1:cp, gs))
	Process_Side(SideFile,gs,GDCgetHostname(Config),GDCgetPort(Config),
				    pathname);
     if (!CanAccess(sockfd,ACC_READ) || !GScanAccess(sockfd, gs, ACC_READ)) {
	  LOGGopher(sockfd, "Denied access for %s", pathname);
	  pathname = BummerMsg;
	  pathname++;
	  startbyte = 0;
	  endbyte = -1;
	  GSdestroy(gs);
	  gs = NULL;
	  goto print_file;
     }
     if (GSgetHeader(gs)==NULL)
	if (GDCgetDHead(Config)!=NULL)
	    GSsetHeader(gs, GDCgetDHead(Config));
     if (GSgetFooter(gs)==NULL)
	if (GDCgetDFoot(Config)!=NULL)
	    GSsetFooter(gs, GDCgetDFoot(Config));
     GSaddDateNsize(gs);
     if (GSgetRHeader(gs)==NULL) {
	inputline[0] = '\0';
	sprintf(inputline,"%s%s '%s'.\r\n\r\n", FromDoc,
		    (strlen(GSgetTitle(gs))>78-strlen(FromDoc))?"\r\n ":"",
				    GSgetTitle(gs));
	GSsetRHeader(gs,inputline);
     }

print_file:
     if (UsingHTML && strcmp(pathname, ".cache.html") != 0) {
	  writestring(sockfd, "<PRE>\r\n");
     }

     if ( (ZeFile = fopen(pathname, "r")) == NULL) {
	  /*
	   * The specified file does not exist
	   */
	  if (gs)
	    GSdestroy(gs);
	  return(FALSE);
     }
     print_aux(sockfd, gs, GS_HEAD);

     if (startbyte != 0) {
	  print_aux(sockfd, gs, GS_RHEAD);
	  fseek(ZeFile, startbyte, 0);
     }

     {
	  FILE *pp;
	  if (pp = specialfile(ZeFile, pathname)) {
	       fclose(ZeFile);
	       ZeFile = pp;
	  }
     }

     while (fgets(inputline, MAXLINE, ZeFile) != NULL) {
	  ZapCRLF(inputline);
	  if (!writeline(sockfd, inputline))
	    return(TRUE);
	  if (endbyte >0) {
	       if (ftell(ZeFile) >= endbyte) {
		    print_aux(sockfd, gs, GS_RFOOT);
		    break;
	       }
	  }
     }

     Specialclose(ZeFile);
     print_aux(sockfd, gs, GS_FOOT);	

     if (UsingHTML && strcmp(pathname, ".cache.html") != 0) {
	  writestring(sockfd, "</PRE>\r\n");
     }

     if (gs)
	GSdestroy(gs);
     /*** Log it ***/
     if (startbyte != 0)
	  LOGGopher(sockfd, "retrieved range %d - %d of file %s", 
				    startbyte, endbyte, pathname);
     else
	  LOGGopher(sockfd, "retrieved file %s", pathname);

     if (NoDOT)
     	  WasThere = writestring(sockfd, "\r\n");
     else
          WasThere = writestring(sockfd, ".\r\n");
     if (WasThere < 0)
	  LOGGopher(-2, ClientWentAway);

     return(TRUE);
}

/*
 *  Write out auxilliaries (Header, Range header, Range footer, Footer)
 *  to Type=0 documents
 */
int
print_aux(int sockfd, GopherStruct *gs, char *auxilliary)
{
    FILE    *AuxFile;
    char    inputline[512];

    if (gs == NULL)
	return(TRUE);

    if (GSgetType(gs) != A_FILE)
	return(TRUE);
    if (strcmp(auxilliary,GS_HEAD)==0)
	auxilliary = GSgetHeader(gs);
    else
    if (strcmp(auxilliary, GS_FOOT)==0)
	auxilliary = GSgetFooter(gs);   
    else 
    if (strcmp(auxilliary, GS_RHEAD)==0)
	auxilliary = GSgetRHeader(gs);
    else
    if (strcmp(auxilliary, GS_RFOOT)==0)
	auxilliary = GSgetRFooter(gs);
    else
	return(TRUE);

    if (auxilliary==NULL)
	return(TRUE);

    if (strlen(auxilliary)==0)
	return(TRUE);

    /* Apply Auxilliary Information */

    if (isadir(auxilliary)==0) {
	/* Auxilliary is a file; append entire file */
	if (AuxFile = fopen(auxilliary,"r")) {
	    while (fgets(inputline, MAXLINE, AuxFile) != NULL) {
		ZapCRLF(inputline);
		if (!writeline(sockfd, inputline))
		    return(TRUE);
	    }
	    fclose(AuxFile);
	}
	return(TRUE);
    }
    /* Auxilliary is a text line; append it */
    strcpy(inputline, auxilliary);
    if (!writeline(sockfd, inputline));
    return(TRUE);
}

/*
 *  Write a line of a file to the client
 */
int
writeline(int sockfd, char *inputline)
{
    /** Period on a line by itself, double it.. **/
    if (*inputline == '.' && inputline[1] == '\0') {
	inputline[1] = '.';
	inputline[2] = '\0';
    }
    strcat(inputline, "\r\n");
    if (writestring(sockfd, inputline) <0) {
	LOGGopher(-2, ClientWentAway);
	return(FALSE);
    }
    return(TRUE);
}

#define BUFSIZE 2048 /* A pretty good value for ethernet */

void
echosound(int sockfd, char *filename)
{
     FILE *SideFile;
     FILE *sndfile;
     unsigned char in[BUFSIZE];
     register int j;
     int gotbytes;
     GopherStruct *gs = NULL;
     char *cp;

#ifdef VMS
     /* Don't accept anything but valid VMS directory specification */
     
     if (Validate_Filespec(filename)==NULL) {
	LOGGopher(sockfd, "Invalid Filespec for %s", filename-1);
	filename = SyntaxErr+1;
     }
     /* Don't allow arbitrary files to be accessed */
     if (strchr(filename,':'))
	if (strncasecmp(filename, GDCgetDataDir(Config),
			    strcspn(GDCgetDataDir(Config),":"))) {
	    LOGGopher(sockfd, "Denied access for %s", filename-1);
	    filename = BummerMsg+1;
	}
#endif
     /*** Check and see if the peer has permissions to read files ***/

     gs = GSnew();
     cp = strchr(filename,']');
     if (SideFile = Build_Lookaside(filename, (cp)?cp+1:cp, gs))
	Process_Side(SideFile,gs,GDCgetHostname(Config),GDCgetPort(Config),
				filename);
     if (!CanAccess(sockfd,ACC_READ) || !GScanAccess(sockfd, gs, ACC_READ)) {
	  LOGGopher(sockfd, "Denied access for %s", filename-1);
	  filename = BummerMsg+1;
     }
     GSdestroy(gs);
#ifdef GOPHER_LIVE_DIGITIZED_SOUND
     if (strcmp(filename, "-") == 0) {
	  /*** Do some live digitization!! **/
	  sndfile = popen("record -", "r");
     }
     else
#endif
	  sndfile = fopen(filename, "r");
	  if (sndfile == NULL) {
	       LOGGopher(sockfd, "Failed to access %s", filename-1);
	       filename = NoSuchFile+1;
	       sndfile = fopen(filename, "r");
	       if (sndfile == NULL) {
	            LOGGopher(sockfd, "Also failed to access %s", filename-1);
	            Abortoutput(sockfd,
		                "Document does not exist","no_such_file");
	            return;
	       }
	  }

     if (filename == SyntaxErr+1) {
          j = writen(sockfd, "Eh? Confusing Request\n\n", 23);
          if (j <= 0) {
	       fclose(sndfile);
	       LOGGopher(-2, ClientWentAway);
	       return;
	  }
     }

     while(1) {
	  gotbytes = fread(in, 1, BUFSIZE, sndfile);
	  
	  if (gotbytes == 0)
	       break;       /*** end of file or error... ***/

          j = writen(sockfd, in, gotbytes);

	  if (j <= 0)
	       break;       /*** yep another error condition ***/

     }
#ifdef GOPHER_LIVE_DIGITIZED_SOUND
     if (strcmp(filename, "-") == 0) {
	  /*** Do some live digitization!! **/
	  pclose(sndfile);
     }
     else
#endif
	  fclose(sndfile);
     if (j <= 0)
	  LOGGopher(-2, ClientWentAway);
     else {
          /* Log it */
          if (*(filename-1)==A_SOUND)
	       LOGGopher(sockfd, "retrieved sound %s", filename);
          else
	       LOGGopher(sockfd, "retrieved binary %s", filename);
     }

}
#ifdef VMS

/*
 *	Continuation on .LINKS, lookasides, and the like would really be nice
 *	so we'll add code to detect a trailing "-", and if the next record in
 *	the file starts with a space we'll concatenate the records up to a max.
 */
int
Continuation(char *buf, FILE *file, int max, char cont)
{
    int	    i, posit;
    char    *cp;

    while((buf[i=(strlen(buf)-1)]==cont) && (i>0)) {
	posit = ftell(file);
	cp=fgets(buf+i,max-i,file);
	if (cp==NULL || buf[i]!=' ') {
	    buf[i++] = cont;
	    buf[i] = '\0';
	    fseek(file,posit,0);
	    return;
	}
	ZapCRLF(buf);
    }
}

/*	A condition handler to catch problems, display who and where, then
 *	resignal so we get a traceback
 */
int
gopher_traceback(int signal[], int mech[])
{
    if (traceback.tx==NULL)
	traceback.tx = "";
    LOGGopher(traceback.socket, "Dying! %s", traceback.tx);
    if (signal[1])
	LOGGopher(traceback.socket, "%s", strerror(EVMSERR, signal[1]));
    if (traceback.socket > -1)
        printf("%s : %s", CurrentPeerName, traceback.tx);
    else
        printf("<> : %s", traceback.tx);
    return(SS$_RESIGNAL);
}


/*	Stolen from SERVERUTIL.C; only part VMS server needs  - JLW
		Assumes that a Hidden file server_error .<errext>
		exists, to be retrieved by a user to explain their error(s).
*/

/* 
 * This routine cleans up an open file descriptor and sends out a bogus
 * filename with the error message
 */

void
Abortoutput(int sockfd, char *errmsg, char *errext)
{
     char outputline[256];
     
     sprintf(outputline,
	"0Server error: %s\t0%s%s%s.%s\t%s\t%d\r\n.\r\n", errmsg, 
		    GDCgetDataDir(Config),GDCgetHiddenPrefix(Config),
			    "server_error", errext, GDCgetHostname(Config),
				    GDCgetPort(Config));
     LOGGopher(sockfd, "Client Abort: %s", errmsg);
     if (writestring(sockfd, outputline)<0) {
	  LOGGopher(-2, ClientWentAway);
	  exit(-1);
     }
     closenet(sockfd);

     return;
}

/**********************
*   Emulate functionality of ropendir() and readdir() for VMS wildcarded search
*/
char *
VMS$wild_search(char *path, int sockfd)
{
     static struct FAB	 wild_fab;  /* Used in wildcard search		    */
     static struct NAM	 wild_nam;  /* Used in conjunction with wild_fab    */
     static char fullname[256];	    /* ropendir() input, readdir() output   */
     static char expanded[256];	    /* filespec after logical expansion	    */
     static char result[256];	    /* result from search		    */
     register    status;
     char *cp;

/* Validate path, initialize for wildcarded search of directory */

     if (path) {
	wild_fab = cc$rms_fab;
	wild_nam = cc$rms_nam;
	wild_fab.fab$b_fac = FAB$M_GET;
	wild_fab.fab$l_fop = FAB$V_NAM;
	wild_fab.fab$l_nam = &wild_nam;
	wild_fab.fab$l_dna = "*.*";
	wild_fab.fab$b_dns = strlen(wild_fab.fab$l_dna);
	wild_nam.nam$l_esa = expanded;
	wild_nam.nam$l_rsa = result;
	wild_nam.nam$b_ess = wild_nam.nam$b_rss = 255;
	wild_fab.fab$l_fna = fullname;
	wild_fab.fab$b_fns = fullname[0] = expanded[0] = result[0] = 0;


	if (((status = SYS$PARSE(&wild_fab)) &1) != 1) {
	    LOGGopher(sockfd,"Error on parse of pathname %s, %s",path,
						    STRerror(errno));
	    return(NULL);
	}
	return(fullname);
     }

/* Get next directory entry */

     if ((( status = SYS$SEARCH(&wild_fab)) &1) != 1) {
	if ( (status == RMS$_NMF) || (status == RMS$_FNF) )
           return(NULL);
	LOGGopher(sockfd,"Error on search, %s",STRerror(errno));
	Abortoutput(sockfd, "Nothing Found", "nothing");
	return(NULL);
     }

     fullname[0] = expanded[wild_nam.nam$b_esl]
			= result[wild_nam.nam$b_rsl] = '\0';
     strcpy(fullname, (char*)strchr(result,']') + 1);
     *((char *)strchr(fullname,';')) = '\0';
     return(fullname);
}

/*
 *  This routine validates a selector path as being a valid VMS file 
 *  specification.
 **/
char *
Validate_Filespec(char *path)
{
     struct FAB	 fab;
     struct NAM	 nam;
     static
        char expanded[256];    
     register    status;
     char *cp;

     for(cp = path; *cp; cp++) if (*cp == ' ') break;

     fab = cc$rms_fab;
     nam = cc$rms_nam;
     fab.fab$b_fac = FAB$M_GET;
     fab.fab$l_fop = FAB$V_NAM;
     fab.fab$l_nam = &nam;
     fab.fab$l_dna = GDCgetDataDir(Config);
     fab.fab$b_dns = strlen(fab.fab$l_dna);
     fab.fab$l_fna = path;
     fab.fab$b_fns = (cp - path);
     nam.nam$l_esa = expanded;
     nam.nam$b_ess = 255;
     nam.nam$b_nop = NAM$V_SYNCHK;
     expanded[0] = 0;
     if ((status = SYS$PARSE(&fab)) != RMS$_NORMAL)
	return(NULL);
     expanded[nam.nam$b_esl] = '\0';
     return(expanded);
}

/*
 *  Modification of Bruce Tanner's vms_system() function.
 *     F.Macrides (MACRIDES@SCI.WFEB.EDU) -- 08-Jul-1993
 *
 *  This routine permits a server started under Inetd/MULTINET_SERVER
 *   to spawn subprocesses with the DCL CLI.
 *
 *  The subprocess is created with LOGINOUT.EXE as its image, so that
 *   it has a DCL CLI, but it has F$MODE() .eqs. "OTHER" and does not
 *   execute SYS$MANAGER:SYLOGIN.COM (furthermore, MULTINET recommends
 *   that you explicitly direct an exit at the top of SYLOGIN.COM for
 *   "OTHER" processes).  To pass the subprocess logicals and foreign
 *   command definitions (most importantly, that for EGREP), you can
 *   define a command file to be executed before the execution of the
 *   gopher server's command, using any of these options:
 *       (1) Define the system logical "GOPHER_LOGIN" to point to the
 *            command file.
 *       (2) Set the "SpawnInit" field in the server's configuration
 *            file so that it points to the command file.
 *       (3) Define the program logical "LOGINCOM" in CONF.H so that
 *            it points to the command file instead of to the system
 *            logical.
 *
 *  The subprocess has its privileges set to only TMPMBX and NETMBX,
 *   but it will be owned by SYSTEM, which grants it privileges you
 *   can't totally restrict (e.g., due to ACL settings and rights
 *   identifiers for SYSTEM).  Therefore, if the server is not running
 *   from Inetd/MULTINET_SERVER, the function reroutes the call to the
 *   C library's system().
 *
 *  The function talks to the subprocess via sys$qiow()'s to a mailbox,
 *   and can hang if the subprocess crashes.  I therefore check that the
 *   subprocess is still alive, via a "throwaway" sys$getjpi() call, after
 *   the server's DCL command has been mailed, and before mailing a suicide
 *   command.  I haven't had any problems since adding this simple trick,
 *   but someday the function should be rewritten to check event flags.
 */

#include <ssdef.h>
#include <iodef.h>
#include <dvidef.h>
#include <prvdef.h>
#include <jpidef.h>
#define check(status) if ((status & 1) != 1) return (status)

int vms_system(char *command)
 {
     char buf[256], mbx_name[20], *cp, username[12];
     long name_len;
     unsigned int pid;
     short chan;
     static int unit;
     int status, iosb[2], privs[2] = {PRV$M_NETMBX|PRV$M_TMPMBX, 0};
     struct itemlist3 {
         short buflen;
         short itmcode;
         int *bufadr;
         short *retadr;
     } itmlst[2] = {
         {4, DVI$_UNIT, (int *) &unit, 0},
         {0, 0, 0, 0}
       };
     struct {
	 short buffer_length;
	 short item_code;
	 char  *buffer_address;
	 long  return_length_address;
	 long  terminator[3];
     } itmlstj;

     $DESCRIPTOR(d_out, "NL:");
     $DESCRIPTOR(d_err, "NL:");
     $DESCRIPTOR(d_image, "sys$system:loginout.exe");
     struct dsc$descriptor_s
          d_input = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};

    /*
     *  If we're not under MULTINET_SERVER/Inetd, use system()
     */
     if (GDCgetInetdActive(Config)==FALSE)
	return(system(command));

    /*
     *  Create a mailbox for passing DCL commands to the subprocess.
     */
     status = sys$crembx(0, &chan, 0, 0, 0, 0, 0, 0);
     check(status);

    /*
     *  Identify the mailbox for the d_input descriptor.
     */
     status = sys$getdviw(0, chan, 0, itmlst, 0, 0, 0, 0);
     check(status);
     sprintf(mbx_name, "_MBA%d:", unit);
     d_input.dsc$w_length = (short) strlen(mbx_name);
     d_input.dsc$a_pointer = mbx_name;

    /*
     *  Create the subprocess with only TMPMBX and NETMBX privileges.
     */
     status = sys$creprc(&pid, &d_image, &d_input, &d_out, &d_err,
		&privs, 0, 0, 4, 0, 0, 0);
     check(status);

    /* 
     *  The subprocess doesn't execute SYLOGIN.COM, and it's F$MODE()
     *  is "OTHER", so pass it the EGREP foreign command, and other
     *  symbols and logicals you want the subprocess to have, via a
     *  command file.  But make sure the subprocess can execute the
     *  command file.
     */
     if (access(GDCgetSpawnInit(Config), 1) == 0) {
          sprintf(buf, "$ @%s", GDCgetSpawnInit(Config));
          status = sys$qiow(0, chan, IO$_WRITEVBLK, &iosb, 0, 0, buf,
                       strlen(buf), 0, 0, 0, 0);
          check(status);
     }

    /*
     *  Mail the server's DCL command to the subprocess.
     */
     status = sys$qiow(0, chan, IO$_WRITEVBLK, &iosb, 0, 0, command,
                       strlen(command), 0, 0, 0, 0);
     check(status);

    /*
     *  Wait a second, and use a non-mailbox service to see if the
     *  command caused the subprocess to crash (so we don't send it
     *  a suicide note and end up hanging ourselves on the mailbox).
     */
     sleep(1);
     itmlstj.buffer_length = 12;
     itmlstj.item_code = JPI$_USERNAME;
     itmlstj.buffer_address = username;
     itmlstj.return_length_address = (long) &name_len;
     itmlstj.terminator[0] = 0;
     itmlstj.terminator[1] = 0;
     itmlstj.terminator[2] = 0;
     name_len = 0;
     status = sys$getjpiw(0, &pid, 0, &itmlstj.buffer_length, &iosb[0], 0, 0);
     check(status);

    /*
     *  If the subprocess is still alive, mail it instructions to
     *  commit suicide (when it's done executing the DCL command).
     */
     sprintf(buf, "$ stop/id=%x", pid);
     status = sys$qiow(0, chan, IO$_WRITEVBLK, &iosb, 0, 0, buf,
                       strlen(buf), 0, 0, 0, 0);
     check(status);

    /*
     * Deassign the mailbox channel.
     */
     status = sys$dassgn(chan);
     check(status);

     return SS$_NORMAL;
}


/*  ROUTINE							WWW_to_VMS()
 *  Replace slash-separated pathspecs with VMS pathspecs.
 *     F.Macrides (MACRIDES@SCI.WFEB.EDU) -- 08-Sep-1994
 *
 *  This routine accepts pathspecs which begin with a slash, and replaces
 *   all slashes to create a VMS pathspec.  If a GType for a directory is
 *   indicated (A_DIRECTORY or '1') and there is no terminal slash, it will
 *   append one before performing the conversion.
 *
 *  The sole purpose of this routine is to allow slashes to be substituted
 *   for ':', ":[", '[' or ']' in the *pathspec* portions of selectors for
 *   gopher URL's, so that they do not need to be escaped to hex notation.
 *   It does *not* do a SHELL$ or POSIX conversion from Unix pathspecs, nor
 *   emulate the pathspec rules for http URL's.  All VMSGopherServer rules
 *   with respect to DataDirectory defaulting, and uses of wildcards and/or
 *   ellipses still apply.  In the pathspec fields of URL's, you simply
 *   replace the above three characters and/or ":[" string with slashes,
 *   and add a lead slash if not already present via the substitutions.
 *
 *  You also can substituTe the dots between subdirectories with slashes,
 *   but the dots in ellipses are associated with the preceding directory
 *   string and should *not* be replaced.  Also, you still must escape
 *   the pair or colons (':' == %3a) which serve as ARG delimiters in exec
 *   (A_EVENT, 'e') and search (A_INDEX, '7') selectors, and any spaces
 *   (' ' == %20) in the selector.  E.g.,
 *      7[foo...]*.txt              can be replaced by:
 *      7/foo.../*.txt
 *         and
 *	7:nosort:[foo...]*.txt      by:
 *    	7%3anosort%3a/foo.../*.txt
 *	   and 
 *      1gopher_root4:[neat.stuff.for.you.to read]   by:
 *      1/gopher_root4/neat/stuff/for/you/to/read/   or:
 *      1/gopher_root4/neat.stuff.for.you.to.read/
 *
 *  Here's a full example of a URL for:
 *                Type=7
 *                Path=7[_shell]search.shell gopher_rooti:[foo]foodoc
 *
 *   On the command line it would be:
 *      gopher://host/77/_shell/search.shell%20/gopher_rooti/foo/foodoc
 *
 *   In a foo.html would be:
 *  <A HREF="gopher://host/77/_shell/search.shell%20/gopher_rooti/foo/foodoc"
 *  >Search the foo database</A>.
 */

char *WWW_to_VMS(char *WWWname, char GType)
{
    static char vmsname[256];
    char *filename=NULL;	/* Working copy of pathspec */
    char *second;		/* 2nd slash */
    char *last;			/* last slash */
    
    if(!WWWname)		/* Make sure we got a pathspec */
	return(NULL);

    filename  = (char*)malloc(strlen(WWWname)+4);
    strcpy(filename, WWWname);	/* If a directory, ensure a terminal slash */
    if(GType == A_DIRECTORY && filename[strlen(filename)-1] != '/')
        strcat(filename, "/");
    
    second = strchr(filename+1, '/');		/* 2nd slash */
    last = strrchr(filename, '/');		/* last slash */
        
    if (!second) {				/* Only one slash */
	sprintf(vmsname, "%s", filename+1);
    } else if(second==last) {			/* Exactly two slashes */
	*second = 0;
	sprintf(vmsname, "[%s]%s", filename+1, second+1);
	*second = '/';
    } else { 					/* More than two slashes */
	char * p;
	*second = 0;		/* Split disk or dir from rest */
	*last = 0;		/* Split dir from filename */
	if(strncasecmp(filename+1, GDCgetDataDir(Config),
			   strcspn(GDCgetDataDir(Config),":")))
	    sprintf(vmsname, "[%s.%s]%s", filename+1, second+1, last+1);
	else
	    sprintf(vmsname, "%s:[%s]%s", filename+1, second+1, last+1);
	*second = *last = '/';	/* restore filename */
	for (p=strchr(vmsname, '['); *p!=']'; p++)
	    if (*p=='/') *p='.';	/* Convert dir sep.  to dots */
    }
    free(filename);
    return vmsname;
}
#endif
