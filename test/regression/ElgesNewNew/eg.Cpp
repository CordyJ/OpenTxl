#ident  "$Revision: 1.17 $"




#ident  "$Revision: 1.5 $"

typedef int 	ptrdiff_t;




#ident  "$Revision: 1.34 $"





#ident  "$Revision: 1.23 $"

extern void *memcpy(void *, const void *, size_t);
extern void *memmove(void *, const void *, size_t);
extern char *strcpy(char *, const char *);

extern char *strncpy(char *, const char *, size_t);

extern char *strcat(char *, const char *);
extern char *strncat(char *, const char *, size_t);

extern int memcmp(const void *, const void *, size_t);
extern int strcmp(const char *, const char *);
extern int strcoll(const char *, const char *);
extern int strncmp(const char *, const char *, size_t);
extern size_t strxfrm(char *, const char *, size_t);

extern void *memchr(const void *, int, size_t);
extern char *strchr(const char *, int);
extern size_t strcspn(const char *, const char *);
extern char *strpbrk(const char *, const char *);
extern char *strrchr(const char *, int);
extern size_t strspn(const char *, const char *);
extern char *strstr(const char *, const char *);
extern char *strtok(char *, const char *);

extern void *memset(void *, int, size_t);
extern char *strerror(int);
extern size_t strlen(const char *);



extern void *memccpy(void *, const void *, int, size_t);




extern char *strdup(const char *);
extern int ffs(int);





 
extern int	strcasecmp(const char *, const char *);
extern int	strncasecmp(const char *, const char *, size_t);













#ident  "$Revision: 1.78 $"
 
















 
 

 
 
 





















#ident  "$Revision: 1.49 $"
 
















 
 

 
 
 

 
























#ident  "$Revision: 1.22 $"
 
















 
 

 
 
 



 



 
 
 

 
 
 
 




#ident 	"$Revision: 3.24 $"

 
























 


















































 










 






















 















 
	 













	 








 














 




 


 















 
 




 






























#ident  "$Revision: 1.15 $"
 
















 
 

 
 
 


 















 
 

 
 
 




#ident 	"$Revision: 3.70 $"



 
typedef unsigned char   uchar_t;
typedef unsigned short  ushort_t;
typedef unsigned int    uint_t;
typedef unsigned long   ulong_t;

 
typedef	char *		addr_t;		 
typedef	char *		caddr_t;	 
typedef	long		daddr_t;	 
typedef	long		pgno_t;		 
typedef	__uint32_t	pfn_t;		 
typedef	short		cnt_t;		 

typedef enum { B_FALSE, B_TRUE } boolean_t;


 










 




 

typedef struct {
        unsigned char	u_bits[16];
} uuid_t, *uuid_p_t;


 










typedef	ushort_t o_mode_t;		 
typedef short	o_dev_t;		 
typedef	ushort_t o_uid_t;		 
typedef	o_uid_t	o_gid_t;		 
typedef	short	o_nlink_t;		 
typedef short	o_pid_t;		 
typedef __uint32_t o_ino_t;		 




typedef __uint64_t	ino64_t;	 


typedef	long		off_t;		 

typedef	__int64_t	off64_t;	 

typedef __scint_t	__scoff_t;	 

typedef __scoff_t	scoff_t;	 



typedef	long		swblk_t;
typedef	unsigned long	paddr_t;	 
typedef	int		key_t;		 
typedef	unsigned char	use_t;		 
typedef	short		sysid_t;
typedef	short		index_t;
typedef unsigned int	lock_t;		 
typedef	signed char	cpuid_t;	 











typedef	long		time_t;		 




typedef	long		clock_t;  




typedef int processorid_t;		 
typedef int toid_t;			 
typedef	long *qaddr_t;		       
typedef __uint32_t inst_t;		 

 





 





typedef	signed char	int8_t;
typedef	short		int16_t;
typedef	__int32_t	int32_t;
typedef	unsigned char	u_int8_t;
typedef	unsigned short	u_int16_t;
typedef	__uint32_t	u_int32_t;


 













 



typedef	long	hostid_t;

 








 



 



















#ident 	"$Revision: 1.2 $"

 




typedef	struct { int r[1]; } *	physadr;
typedef	unsigned char	unchar;
typedef	unsigned char	u_char;
typedef	unsigned short	ushort;
typedef	unsigned short	u_short;
typedef	unsigned int	uint;
typedef	unsigned int	u_int;
typedef	unsigned long	ulong;
typedef	unsigned long	u_long;
typedef	struct	_quad { long val[2]; } quad;



 















 
 
 

 
 
 
 




#ident 	"$Revision: 1.4 $"

 





















typedef	struct fd_set {
	fd_mask	fds_bits[((( 1024  )+((  (sizeof(fd_mask) * 8 )  )-1))/(  (sizeof(fd_mask) * 8 )  )) ];
} fd_set;
















 
typedef struct {                 
        __uint32_t sigbits[2];
} k_sigset_t;
typedef __uint32_t k_fltset_t;      








 
 
 

 
 
 

 
#ident 	"$Revision: 3.37 $"





 















 







 






















 






 


typedef struct flock {
	short	l_type;
	short	l_whence;
	off_t	l_start;
	off_t	l_len;		 
        long	l_sysid;
        pid_t	l_pid;
	long	pad[4];		 
} flock_t;







 






 













extern int fcntl(int, int, ...);
extern int open(const char *, int, ...);
extern int creat(const char *, mode_t);







extern "C" {
int strcasecmp _G_ARGS((const char*, const char*));
}




 

 






















struct IntRep                     
{
  unsigned short  len;           
  unsigned short  sz;            
  short           sgn;           
  unsigned short  s[1];          
};

 
 


extern IntRep*  Ialloc(IntRep*, const unsigned short *, int, int, int);
extern IntRep*  Icalloc(IntRep*, int);
extern IntRep*  Icopy_ulong(IntRep*, unsigned long);
extern IntRep*  Icopy_long(IntRep*, long);
extern IntRep*  Icopy(IntRep*, const IntRep*);
extern IntRep*  Iresize(IntRep*, int);
extern IntRep*  add(const IntRep*, int, const IntRep*, int, IntRep*);
extern IntRep*  add(const IntRep*, int, long, IntRep*);
extern IntRep*  multiply(const IntRep*, const IntRep*, IntRep*);
extern IntRep*  multiply(const IntRep*, long, IntRep*);
extern IntRep*  lshift(const IntRep*, long, IntRep*);
extern IntRep*  lshift(const IntRep*, const IntRep*, int, IntRep*);
extern IntRep*  bitop(const IntRep*, const IntRep*, IntRep*, char);
extern IntRep*  bitop(const IntRep*, long, IntRep*, char);
extern IntRep*  power(const IntRep*, long, IntRep*);
extern IntRep*  div(const IntRep*, const IntRep*, IntRep*);
extern IntRep*  mod(const IntRep*, const IntRep*, IntRep*);
extern IntRep*  div(const IntRep*, long, IntRep*);
extern IntRep*  mod(const IntRep*, long, IntRep*);
extern IntRep*  compl(const IntRep*, IntRep*);
extern IntRep*  abs(const IntRep*, IntRep*);
extern IntRep*  negate(const IntRep*, IntRep*);
extern IntRep*  pow(const IntRep*, long);
extern IntRep*  gcd(const IntRep*, const IntRep* y);
extern int      compare(const IntRep*, const IntRep*);
extern int      compare(const IntRep*, long);
extern int      ucompare(const IntRep*, const IntRep*);
extern int      ucompare(const IntRep*, long);
extern char*    Itoa(const IntRep* x, int base = 10, int width = 0);
extern char*    cvtItoa(const IntRep* x, char* fmt, int& fmtlen, int base,
                        int showbase, int width, int align_right, 
                        char fillchar, char Xcase, int showpos);
extern IntRep*  atoIntRep(const char* s, int base = 10);
extern long     Itolong(const IntRep*);
extern int      Iislong(const IntRep*);
extern long     lg(const IntRep*);

extern IntRep _ZeroRep, _OneRep, _MinusOneRep;

class Integer
{
protected:
  IntRep*         rep;

private:
                  Integer(int);
                  Integer(long);
  struct AllocQNode
  {
    void*  ptr;
    int    sz;
  };
	                  Integer();
                  Integer(int);
                  Integer(long);
                  Integer(unsigned long);

public:
                  Integer();
                  Integer(int);
                  Integer(long);
                  Integer(unsigned long);
                  Integer(IntRep*);
                  Integer(const Integer&);

                  ~Integer();

  void            operator =  (const Integer&);
  void            operator =  (long);

 

  void            operator ++ ();
  void            operator -- ();
  void            negate();           
  void            abs();              
  void            complement();       

 

  void            operator += (const Integer&);
  void            operator -= (const Integer&);
  void            operator *= (const Integer&);
  void            operator /= (const Integer&);
  void            operator %= (const Integer&);
  void            operator <<=(const Integer&);
  void            operator >>=(const Integer&);
  void            operator &= (const Integer&);
  void            operator |= (const Integer&);
  void            operator ^= (const Integer&);

  void            operator += (long);
  void            operator -= (long);
  void            operator *= (long);
  void            operator /= (long);
  void            operator %= (long);
  void            operator <<=(long);
  void            operator >>=(long);
  void            operator &= (long);
  void            operator |= (long);
  void            operator ^= (long);

 



 

  friend long     lg (const Integer&);  
  friend double   ratio(const Integer& x, const Integer& y);
                   

  friend Integer  gcd(const Integer&, const Integer&);
  friend int      even(const Integer&);  
  friend int      odd(const Integer&);  
  friend int      sign(const Integer&);  

  friend void     (setbit)(Integer& x, long b);    
  friend void     clearbit(Integer& x, long b);  
  friend int      testbit(const Integer& x, long b);   

 

  friend void     abs(const Integer& x, Integer& dest);
  friend void     negate(const Integer& x, Integer& dest);
  friend void     complement(const Integer& x, Integer& dest);

  friend int      compare(const Integer&, const Integer&);  
  friend int      ucompare(const Integer&, const Integer&); 
  friend void     add(const Integer& x, const Integer& y, Integer& dest);
  friend void     sub(const Integer& x, const Integer& y, Integer& dest);
  friend void     mul(const Integer& x, const Integer& y, Integer& dest);
  friend void     div(const Integer& x, const Integer& y, Integer& dest);
  friend void     mod(const Integer& x, const Integer& y, Integer& dest);
  friend void     divide(const Integer& x, const Integer& y, 
                         Integer& q, Integer& r);
  friend void     and(const Integer& x, const Integer& y, Integer& dest);
  friend void     or(const Integer& x, const Integer& y, Integer& dest);
  friend void     xor(const Integer& x, const Integer& y, Integer& dest);
  friend void     lshift(const Integer& x, const Integer& y, Integer& dest);
  friend void     rshift(const Integer& x, const Integer& y, Integer& dest);
  friend void     pow(const Integer& x, const Integer& y, Integer& dest);

  friend int      compare(const Integer&, long);  
  friend int      ucompare(const Integer&, long); 
  friend void     add(const Integer& x, long y, Integer& dest);
  friend void     sub(const Integer& x, long y, Integer& dest);
  friend void     mul(const Integer& x, long y, Integer& dest);
  friend void     div(const Integer& x, long y, Integer& dest);
  friend void     mod(const Integer& x, long y, Integer& dest);
  friend void     divide(const Integer& x, long y, Integer& q, long& r);
  friend void     and(const Integer& x, long y, Integer& dest);
  friend void     or(const Integer& x, long y, Integer& dest);
  friend void     xor(const Integer& x, long y, Integer& dest);
  friend void     lshift(const Integer& x, long y, Integer& dest);
  friend void     rshift(const Integer& x, long y, Integer& dest);
  friend void     pow(const Integer& x, long y, Integer& dest);

  friend int      compare(long, const Integer&);  
  friend int      ucompare(long, const Integer&); 
  friend void     add(long x, const Integer& y, Integer& dest);
  friend void     sub(long x, const Integer& y, Integer& dest);
  friend void     mul(long x, const Integer& y, Integer& dest);
  friend void     and(long x, const Integer& y, Integer& dest);
  friend void     or(long x, const Integer& y, Integer& dest);
  friend void     xor(long x, const Integer& y, Integer& dest);

 

  int             fits_in_long() const { return Iislong(rep); }
  int             fits_in_double() const;

  long		  as_long() const { return Itolong(rep); }
  double	  as_double() const;

  friend char*    Itoa(const Integer& x, int base = 10, int width = 0);
  friend Integer  atoI(const char* s, int base = 10);
  void		  printon(ostream& s, int base = 10, int width = 0) const;
  
  friend istream& operator >> (istream& s, Integer& y);
  friend ostream& operator << (ostream& s, const Integer& y);

 

  int             initialized() const;
  void   error(const char* msg) const;
  int             OK() const;  
};


 

  int      operator == (const Integer&, const Integer&);
  int      operator == (const Integer&, long);
  int      operator != (const Integer&, const Integer&);
  int      operator != (const Integer&, long);
  int      operator <  (const Integer&, const Integer&);
  int      operator <  (const Integer&, long);
  int      operator <= (const Integer&, const Integer&);
  int      operator <= (const Integer&, long);
  int      operator >  (const Integer&, const Integer&);
  int      operator >  (const Integer&, long);
  int      operator >= (const Integer&, const Integer&);
  int      operator >= (const Integer&, long);
  Integer  operator -  (const Integer&);
  Integer  operator ~  (const Integer&);
  Integer  operator +  (const Integer&, const Integer&);
  Integer  operator +  (const Integer&, long);
  Integer  operator +  (long, const Integer&);
  Integer  operator -  (const Integer&, const Integer&);
  Integer  operator -  (const Integer&, long);
  Integer  operator -  (long, const Integer&);
  Integer  operator *  (const Integer&, const Integer&);
  Integer  operator *  (const Integer&, long);
  Integer  operator *  (long, const Integer&);
  Integer  operator /  (const Integer&, const Integer&);
  Integer  operator /  (const Integer&, long);
  Integer  operator %  (const Integer&, const Integer&);
  Integer  operator %  (const Integer&, long);
  Integer  operator << (const Integer&, const Integer&);
  Integer  operator << (const Integer&, long);
  Integer  operator >> (const Integer&, const Integer&);
  Integer  operator >> (const Integer&, long);
  Integer  operator &  (const Integer&, const Integer&);
  Integer  operator &  (const Integer&, long);
  Integer  operator &  (long, const Integer&);
  Integer  operator |  (const Integer&, const Integer&);
  Integer  operator |  (const Integer&, long);
  Integer  operator |  (long, const Integer&);
  Integer  operator ^  (const Integer&, const Integer&);
  Integer  operator ^  (const Integer&, long);
  Integer  operator ^  (long, const Integer&);

  Integer  abs(const Integer&);  
  Integer  sqr(const Integer&);  

  Integer  pow(const Integer& x, const Integer& y);
  Integer  pow(const Integer& x, long y);
  Integer  Ipow(long x, long y);  


extern char*    dec(const Integer& x, int width = 0);
extern char*    oct(const Integer& x, int width = 0);
extern char*    hex(const Integer& x, int width = 0);
extern Integer  sqrt(const Integer&);  
extern Integer  lcm(const Integer& x, const Integer& y);  


typedef Integer IntTmp;  

inline Integer::Integer() :rep(&_ZeroRep) {}

inline Integer::Integer(IntRep* r) :rep(r) {}

inline Integer::Integer(int y) :rep(Icopy_long(0, (long)y)) {}

inline Integer::Integer(long y) :rep(Icopy_long(0, y)) {}

inline Integer::Integer(unsigned long y) :rep(Icopy_ulong(0, y)) {}

inline Integer::Integer(const Integer&  y) :rep(Icopy(0, y.rep)) {}

inline Integer::~Integer() { if (rep && !(( rep )->sz==0) ) delete rep; }

inline void  Integer::operator = (const Integer&  y)
{
  rep = Icopy(rep, y.rep);
}

inline void Integer::operator = (long y)
{
  rep = Icopy_long(rep, y); 
}

inline int Integer::initialized() const
{
  return rep != 0;
}

 

inline int compare(const Integer& x, const Integer& y)
{
  return compare(x.rep, y.rep);
}

inline int ucompare(const Integer& x, const Integer& y)
{
  return ucompare(x.rep, y.rep);
}

inline int compare(const Integer& x, long y)
{
  return compare(x.rep, y);
}

inline int ucompare(const Integer& x, long y)
{
  return ucompare(x.rep, y);
}

inline int compare(long x, const Integer& y)
{
  return -compare(y.rep, x);
}

inline int ucompare(long x, const Integer& y)
{
  return -ucompare(y.rep, x);
}

inline void  add(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = add(x.rep, 0, y.rep, 0, dest.rep);
}

inline void  sub(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = add(x.rep, 0, y.rep, 1, dest.rep);
}

inline void  mul(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = multiply(x.rep, y.rep, dest.rep);
}

inline void  div(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = div(x.rep, y.rep, dest.rep);
}

inline void  mod(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = mod(x.rep, y.rep, dest.rep);
}

inline void  and(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(x.rep, y.rep, dest.rep, '&');
}

inline void  or(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(x.rep, y.rep, dest.rep, '|');
}

inline void  xor(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(x.rep, y.rep, dest.rep, '^');
}

inline void  lshift(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = lshift(x.rep, y.rep, 0, dest.rep);
}

inline void  rshift(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = lshift(x.rep, y.rep, 1, dest.rep);
}

inline void  pow(const Integer& x, const Integer& y, Integer& dest)
{
  dest.rep = power(x.rep, Itolong(y.rep), dest.rep);  
}

inline void  add(const Integer& x, long y, Integer& dest)
{
  dest.rep = add(x.rep, 0, y, dest.rep);
}

inline void  sub(const Integer& x, long y, Integer& dest)
{
  dest.rep = add(x.rep, 0, -y, dest.rep);
}

inline void  mul(const Integer& x, long y, Integer& dest)
{
  dest.rep = multiply(x.rep, y, dest.rep);
}

inline void  div(const Integer& x, long y, Integer& dest)
{
  dest.rep = div(x.rep, y, dest.rep);
}

inline void  mod(const Integer& x, long y, Integer& dest)
{
  dest.rep = mod(x.rep, y, dest.rep);
}

inline void  and(const Integer& x, long y, Integer& dest)
{
  dest.rep = bitop(x.rep, y, dest.rep, '&');
}

inline void  or(const Integer& x, long y, Integer& dest)
{
  dest.rep = bitop(x.rep, y, dest.rep, '|');
}

inline void  xor(const Integer& x, long y, Integer& dest)
{
  dest.rep = bitop(x.rep, y, dest.rep, '^');
}

inline void  lshift(const Integer& x, long y, Integer& dest)
{
  dest.rep = lshift(x.rep, y, dest.rep);
}

inline void  rshift(const Integer& x, long y, Integer& dest)
{
  dest.rep = lshift(x.rep, -y, dest.rep);
}

inline void  pow(const Integer& x, long y, Integer& dest)
{
  dest.rep = power(x.rep, y, dest.rep);
}

inline void abs(const Integer& x, Integer& dest)
{
  dest.rep = abs(x.rep, dest.rep);
}

inline void negate(const Integer& x, Integer& dest)
{
  dest.rep = negate(x.rep, dest.rep);
}

inline void complement(const Integer& x, Integer& dest)
{
  dest.rep = compl(x.rep, dest.rep);
}

inline void  add(long x, const Integer& y, Integer& dest)
{
  dest.rep = add(y.rep, 0, x, dest.rep);
}

inline void  sub(long x, const Integer& y, Integer& dest)
{
  dest.rep = add(y.rep, 1, x, dest.rep);
}

inline void  mul(long x, const Integer& y, Integer& dest)
{
  dest.rep = multiply(y.rep, x, dest.rep);
}

inline void  and(long x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(y.rep, x, dest.rep, '&');
}

inline void  or(long x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(y.rep, x, dest.rep, '|');
}

inline void  xor(long x, const Integer& y, Integer& dest)
{
  dest.rep = bitop(y.rep, x, dest.rep, '^');
}


 

inline int operator == (const Integer&  x, const Integer&  y)
{
  return compare(x, y) == 0; 
}

inline int operator == (const Integer&  x, long y)
{
  return compare(x, y) == 0; 
}

inline int operator != (const Integer&  x, const Integer&  y)
{
  return compare(x, y) != 0; 
}

inline int operator != (const Integer&  x, long y)
{
  return compare(x, y) != 0; 
}

inline int operator <  (const Integer&  x, const Integer&  y)
{
  return compare(x, y) <  0; 
}

inline int operator <  (const Integer&  x, long y)
{
  return compare(x, y) <  0; 
}

inline int operator <= (const Integer&  x, const Integer&  y)
{
  return compare(x, y) <= 0; 
}

inline int operator <= (const Integer&  x, long y)
{
  return compare(x, y) <= 0; 
}

inline int operator >  (const Integer&  x, const Integer&  y)
{
  return compare(x, y) >  0; 
}

inline int operator >  (const Integer&  x, long y)
{
  return compare(x, y) >  0; 
}

inline int operator >= (const Integer&  x, const Integer&  y)
{
  return compare(x, y) >= 0; 
}

inline int operator >= (const Integer&  x, long y)
{
  return compare(x, y) >= 0; 
}


inline void  Integer::operator += (const Integer& y)
{
  add(*this, y, *this);
}

inline void  Integer::operator += (long y)
{
  add(*this, y, *this);
}

inline void Integer::operator ++ ()
{
  add(*this, 1, *this);
}


inline void  Integer::operator -= (const Integer& y)
{
  sub(*this, y, *this);
}

inline void  Integer::operator -= (long y)
{
  sub(*this, y, *this);
}

inline void Integer::operator -- ()
{
  add(*this, -1, *this);
}



inline void Integer::operator *= (const Integer& y)
{
  mul(*this, y, *this);
}

inline void Integer::operator *= (long y)
{
  mul(*this, y, *this);
}


inline void  Integer::operator &= (const Integer& y)
{
  and(*this, y, *this);
}

inline void  Integer::operator &= (long y)
{
  and(*this, y, *this);
}

inline void  Integer::operator |= (const Integer& y)
{
  or(*this, y, *this);
}

inline void  Integer::operator |= (long y)
{
  or(*this, y, *this);
}


inline void  Integer::operator ^= (const Integer& y)
{
  xor(*this, y, *this);
}

inline void  Integer::operator ^= (long y)
{
  xor(*this, y, *this);
}



inline void Integer::operator /= (const Integer& y)
{
  div(*this, y, *this);
}

inline void Integer::operator /= (long y)
{
  div(*this, y, *this);
}


inline void Integer::operator <<= (const Integer&  y)
{
  lshift(*this, y, *this);
}

inline void Integer::operator <<= (long  y)
{
  lshift(*this, y, *this);
}


inline void Integer::operator >>= (const Integer&  y)
{
  rshift(*this, y, *this);
}

inline void  Integer::operator >>= (long y)
{
  rshift(*this, y, *this);
}




inline void Integer::abs()
{
  ::abs(*this, *this);
}

inline void Integer::negate()
{
  ::negate(*this, *this);
}


inline void Integer::complement()
{
  ::complement(*this, *this);
}


inline int sign(const Integer& x)
{
  return (x.rep->len == 0) ? 0 : ( (x.rep->sgn == 1) ? 1 : -1 );
}

inline int even(const Integer& y)
{
  return y.rep->len == 0 || !(y.rep->s[0] & 1);
}

inline int odd(const Integer& y)
{
  return y.rep->len > 0 && (y.rep->s[0] & 1);
}

inline char* Itoa(const Integer& y, int base, int width)
{
  return Itoa(y.rep, base, width);
}



inline long lg(const Integer& x) 
{
  return lg(x.rep);
}

 



inline Integer  operator +  (const Integer& x, const Integer& y) 
{
  Integer r; add(x, y, r); return r;
}

inline Integer  operator +  (const Integer& x, long y) 
{
  Integer r; add(x, y, r); return r;
}

inline Integer  operator +  (long  x, const Integer& y) 
{
  Integer r; add(x, y, r); return r;
}

inline Integer  operator -  (const Integer& x, const Integer& y) 
{
  Integer r; sub(x, y, r); return r;
}

inline Integer  operator -  (const Integer& x, long y) 
{
  Integer r; sub(x, y, r); return r;
}

inline Integer  operator -  (long  x, const Integer& y) 
{
  Integer r; sub(x, y, r); return r;
}

inline Integer  operator *  (const Integer& x, const Integer& y) 
{
  Integer r; mul(x, y, r); return r;
}

inline Integer  operator *  (const Integer& x, long y) 
{
  Integer r; mul(x, y, r); return r;
}

inline Integer  operator *  (long  x, const Integer& y) 
{
  Integer r; mul(x, y, r); return r;
}

inline Integer sqr(const Integer& x) 
{
  Integer r; mul(x, x, r); return r;
}

inline Integer  operator &  (const Integer& x, const Integer& y) 
{
  Integer r; and(x, y, r); return r;
}

inline Integer  operator &  (const Integer& x, long y) 
{
  Integer r; and(x, y, r); return r;
}

inline Integer  operator &  (long  x, const Integer& y) 
{
  Integer r; and(x, y, r); return r;
}

inline Integer  operator |  (const Integer& x, const Integer& y) 
{
  Integer r; or(x, y, r); return r;
}

inline Integer  operator |  (const Integer& x, long y) 
{
  Integer r; or(x, y, r); return r;
}

inline Integer  operator |  (long  x, const Integer& y) 
{
  Integer r; or(x, y, r); return r;
}

inline Integer  operator ^  (const Integer& x, const Integer& y) 
{
  Integer r; xor(x, y, r); return r;
}

inline Integer  operator ^  (const Integer& x, long y) 
{
  Integer r; xor(x, y, r); return r;
}

inline Integer  operator ^  (long  x, const Integer& y) 
{
  Integer r; xor(x, y, r); return r;
}

inline Integer  operator /  (const Integer& x, const Integer& y) 
{
  Integer r; div(x, y, r); return r;
}

inline Integer operator /  (const Integer& x, long y) 
{
  Integer r; div(x, y, r); return r;
}

inline Integer operator %  (const Integer& x, const Integer& y) 
{
  Integer r; mod(x, y, r); return r;
}

inline Integer operator %  (const Integer& x, long y) 
{
  Integer r; mod(x, y, r); return r;
}

inline Integer operator <<  (const Integer& x, const Integer& y) 
{
  Integer r; lshift(x, y, r); return r;
}

inline Integer operator <<  (const Integer& x, long y) 
{
  Integer r; lshift(x, y, r); return r;
}

inline Integer operator >>  (const Integer& x, const Integer& y) 
{
  Integer r; rshift(x, y, r); return r;
}

inline Integer operator >>  (const Integer& x, long y) 
{
  Integer r; rshift(x, y, r); return r;
}

inline Integer pow(const Integer& x, long y) 
{
  Integer r; pow(x, y, r); return r;
}

inline Integer Ipow(long x, long y) 
{
  Integer r(x); pow(r, y, r); return r;
}

inline Integer pow(const Integer& x, const Integer& y) 
{
  Integer r; pow(x, y, r); return r;
}



inline Integer abs(const Integer& x) 
{
  Integer r; abs(x, r); return r;
}

inline Integer operator - (const Integer& x) 
{
  Integer r; negate(x, r); return r;
}

inline Integer operator ~ (const Integer& x) 
{
  Integer r; complement(x, r); return r;
}

inline Integer  atoI(const char* s, int base) 
{
  Integer r; r.rep = atoIntRep(s, base); return r;
}

inline Integer  gcd(const Integer& x, const Integer& y) 
{
  Integer r; r.rep = gcd(x.rep, y.rep); return r;
}



inline void Integer::operator %= (const Integer& y)
{
  *this = *this % y;  
}

inline void Integer::operator %= (long y)
{
  *this = *this % y;  
}


 

 
















 









 
 



















 





























typedef void (*one_arg_error_handler_t)(const char*);
typedef void (*two_arg_error_handler_t)(const char*, const char*);

long         gcd(long, long);
long         lg(unsigned long); 
double       pow(double, long);
long         pow(long, long);

extern "C" double       start_timer();
extern "C" double       return_elapsed_time(double last_time = 0.0);

char*        dtoa(double x, char cvt = 'g', int width = 0, int prec = 6);

unsigned int hashpjw(const char*);
unsigned int multiplicativehash(int);
unsigned int foldhash(double);

extern void  default_one_arg_error_handler(const char*);
extern void  default_two_arg_error_handler(const char*, const char*);

extern two_arg_error_handler_t lib_error_handler;

extern two_arg_error_handler_t 
       set_lib_error_handler(two_arg_error_handler_t f);


double abs(double arg);
float abs(float arg);
short abs(short arg);
long abs(long arg);
int sign(long arg);
int sign(double arg);
long sqr(long arg);
double sqr(double arg);
int even(long arg);
int odd(long arg);
long lcm(long x, long y);
void (setbit)(long& x, long b);
void clearbit(long& x, long b);
int testbit(long x, long b);




inline double abs(double arg) 
{
  return (arg < 0.0)? -arg : arg;
}


inline float abs(float arg) 
{
  return (arg < 0.0)? -arg : arg;
}

inline short abs(short arg) 
{
  return (arg < 0)? -arg : arg;
}

inline long abs(long arg) 
{
  return (arg < 0)? -arg : arg;
}

inline int sign(long arg)
{
  return (arg == 0) ? 0 : ( (arg > 0) ? 1 : -1 );
}

inline int sign(double arg)
{
  return (arg == 0.0) ? 0 : ( (arg > 0.0) ? 1 : -1 );
}

inline long sqr(long arg)
{
  return arg * arg;
}


inline double sqr(double arg)
{
  return arg * arg;
}


inline int even(long arg)
{
  return !(arg & 1);
}

inline int odd(long arg)
{
  return (arg & 1);
}

inline long lcm(long x, long y)
{
  return x / gcd(x, y) * y;
}

inline void (setbit)(long& x, long b)
{
  x |= (1 << b);
}

inline void clearbit(long& x, long b)
{
  x &= ~(1 << b);
}

inline int testbit(long x, long b)
{
  return ((x & (1 << b)) != 0);
}





typedef unsigned short uint16;
typedef short int16;
typedef unsigned long  uint32;
typedef long int32;







extern uint16 Fix_default_length;
extern int    Fix_default_print_width;

struct _Frep                     
{
  uint16 len;          		 
  uint16 siz;			 
  int16 ref;          		 
  uint16 s[1];			 
};

typedef _Frep* _Fix;

extern _Frep _Frep_0;
extern _Frep _Frep_m1;
extern _Frep _Frep_quotient_bump;

class Fix
{
  _Fix            rep;

		  Fix(_Fix);

  void		  unique();

public:
		  Fix();
                  Fix(Fix&);
		  Fix(double);
                  Fix(int);
                  Fix(int, const Fix&);
                  Fix(int, double);
                  Fix(int, const _Fix);

                  ~Fix();

  Fix             operator =  (Fix&);
  Fix             operator =  (double);

  friend int      operator == (const Fix&, const Fix& );
  friend int      operator != (const Fix&, const Fix&);

  friend int      operator <  (const Fix&, const Fix&);
  friend int      operator <= (const Fix&, const Fix&);
  friend int      operator >  (const Fix&, const Fix&);
  friend int      operator >= (const Fix&, const Fix&);

  Fix&            operator +  ();
  Fix             operator -  ();

  friend Fix      operator +  (Fix&, Fix&);
  friend Fix      operator -  (Fix&, Fix&);
  friend Fix      operator *  (Fix&, Fix&);
  friend Fix      operator /  (Fix&, Fix&);

  friend Fix      operator *  (Fix&, int);
  friend Fix      operator *  (int, Fix&);
  friend Fix      operator %  (Fix&, int);
  friend Fix      operator << (Fix&, int);
  friend Fix      operator >> (Fix&, int);



  Fix            operator += (Fix&);
  Fix            operator -= (Fix&);
  Fix            operator *= (Fix&);
  Fix            operator /= (Fix&);

  Fix            operator *= (int);
  Fix            operator %= (int);
  Fix            operator <<=(int);
  Fix            operator >>=(int);

  friend char*    Ftoa(Fix&, int width = Fix_default_print_width);
  void		  printon(ostream&, int width = Fix_default_print_width) const;
  friend Fix      atoF(const char*, int len = Fix_default_length);
  
  friend istream& operator >> (istream&, Fix&);
  friend ostream& operator << (ostream&, const Fix&);

   
  friend Fix      abs(Fix);		 
  friend int      sgn(Fix&);		 
  friend Integer  mantissa(Fix&);	 
  friend double   value(const Fix&);	 
  friend int      length(const Fix&);	 
  friend void	  show(Fix&);		 

   
  void            error(const char* msg);		 
  void            range_error(const char* msg);	 

   
  friend void	  mask(_Fix);
  friend int      compare(const _Fix, const _Fix = &_Frep_0);

  friend _Fix	  new_Fix(uint16);
  friend _Fix	  new_Fix(uint16, const _Fix);
  friend _Fix	  new_Fix(uint16, double);

  friend _Fix	  copy(const _Fix, _Fix);
  friend _Fix	  negate(_Fix, _Fix = 0 );
  friend _Fix	  add(_Fix, _Fix, _Fix = 0 );
  friend _Fix	  subtract(_Fix, _Fix, _Fix = 0 );
  friend _Fix	  multiply(_Fix, _Fix, _Fix = 0 );
  friend _Fix	  multiply(_Fix, int, _Fix = 0 );
  friend _Fix	  divide(_Fix, _Fix, _Fix = 0 , _Fix = 0 );
  friend _Fix	  shift(_Fix, int, _Fix = 0 );

   
  friend void	  negate(Fix& x, Fix& r);
  friend void	  add(Fix& x, Fix& y, Fix& r);
  friend void	  subtract(Fix& x, Fix& y, Fix& r);
  friend void	  multiply(Fix& x, Fix& y, Fix& r);
  friend void	  divide(Fix& x, Fix& y, Fix& q, Fix& r);
  friend void	  shift(Fix& x, int y, Fix& r);
};

 

extern void	
  default_Fix_error_handler(const char*),
  default_Fix_range_error_handler(const char*);

extern one_arg_error_handler_t 
  Fix_error_handler,
  Fix_range_error_handler;

extern one_arg_error_handler_t 
  set_Fix_error_handler(one_arg_error_handler_t f),
  set_Fix_range_error_handler(one_arg_error_handler_t f);

typedef void (*Fix_peh)(_Fix&);
extern Fix_peh Fix_overflow_handler;

extern void 
  Fix_overflow_saturate(_Fix&),
  Fix_overflow_wrap(_Fix&),
  Fix_overflow_warning_saturate(_Fix&),
  Fix_overflow_warning(_Fix&),
  Fix_overflow_error(_Fix&);

extern Fix_peh set_overflow_handler(Fix_peh);

extern int Fix_set_default_length(int);

 


inline void Fix::unique()
{
  if ( rep->ref > 1 )
  {
    rep->ref--;
    rep = new_Fix(rep->len,rep);
  }
}

inline void mask (_Fix x)
{
  int n = x->len & 0x0f;
  if ( n )
    x->s[x->siz - 1] &= 0xffff0000 >> n; 
}

inline _Fix copy(const _Fix from, _Fix to)
{
  uint16 *ts = to->s, *fs = from->s;
  int ilim = to->siz < from->siz ? to->siz : from->siz;
  for ( int i=0; i < ilim; i++ )
    *ts++ = *fs++;
  for ( ; i < to->siz; i++ )
    *ts++ = 0;
  mask(to);
  return to;
}

inline Fix::Fix(_Fix f)
{
  rep = f;
}

inline Fix::Fix()
{
  rep = new_Fix(Fix_default_length);
}

inline Fix::Fix(int len)
{
  if ( len < 1  || len > 65535  )
    error("illegal length in declaration");
  rep = new_Fix((uint16 )len);
}

inline Fix::Fix(double d)
{
  rep = new_Fix(Fix_default_length,d);
}

inline Fix::Fix(Fix&  y)
{
  rep = y.rep; rep->ref++;
}

inline Fix::Fix(int len, const Fix&  y)
{
  if ( len < 1  || len > 65535  )
    error("illegal length in declaration");
  rep = new_Fix((uint16 )len,y.rep);
}

inline Fix::Fix(int len, const _Fix fr)
{
  if ( len < 	1  || len > 	65535  )
    error("illegal length in declaration");
  rep = new_Fix((uint16 )len,fr);
}

inline Fix::Fix(int len, double d)
{
  if ( len < 1  || len > 65535  )
    error("illegal length in declaration");
  rep = new_Fix((uint16 )len,d);
}

inline Fix::~Fix()
{
  if ( --rep->ref <= 0 ) delete rep;
}

inline Fix  Fix::operator = (Fix&  y)
{
  if ( rep->len == y.rep->len ) {
    ++y.rep->ref;
    if ( --rep->ref <= 0 ) delete rep;
    rep = y.rep; 
  }
  else {
    unique();
    copy(y.rep,rep);
  }
  return *this;
}

inline Fix  Fix::operator = (double d)
{
  int oldlen = rep->len;
  if ( --rep->ref <= 0 ) delete rep;
  rep = new_Fix(oldlen,d);
  return *this;
}

inline int operator == (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) == 0; 
}

inline int operator != (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) != 0; 
}

inline int operator <  (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) <  0; 
}

inline int operator <= (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) <= 0; 
}

inline int operator >  (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) >  0; 
}

inline int operator >= (const Fix&  x, const Fix&  y)
{
  return compare(x.rep, y.rep) >= 0; 
}

inline Fix& Fix::operator +  ()
{
  return *this;
}

inline Fix Fix::operator -  ()
{
  _Fix r = negate(rep); return r;
}

inline Fix      operator +  (Fix&  x, Fix& y)
{
  _Fix r = add(x.rep, y.rep); return r;
}

inline Fix      operator -  (Fix&  x, Fix& y)
{
  _Fix r = subtract(x.rep, y.rep); return r;
}

inline Fix      operator *  (Fix&  x, Fix& y)
{
  _Fix r = multiply(x.rep, y.rep); return r;
}

inline Fix      operator *  (Fix&  x, int y)
{
  _Fix r = multiply(x.rep, y); return r;
}

inline Fix      operator *  (int  y, Fix& x)
{
  _Fix r = multiply(x.rep, y); return r;
}

inline Fix operator / (Fix& x, Fix& y)
{
  _Fix r = divide(x.rep, y.rep); return r;
}

inline Fix  Fix::operator += (Fix& y)
{
  unique(); add(rep, y.rep, rep); return *this;
}

inline Fix  Fix::operator -= (Fix& y)
{
  unique(); subtract(rep, y.rep, rep); return *this;
}

inline Fix  Fix::operator *= (Fix& y)
{
  unique(); multiply(rep, y.rep, rep); return *this;
}

inline Fix  Fix::operator *= (int y)
{
  unique(); multiply(rep, y, rep); return *this;
}

inline Fix Fix::operator /= (Fix& y)
{
  unique(); divide(rep, y.rep, rep); return *this;
}

inline Fix operator % (Fix& x, int y)
{
  Fix r((int )x.rep->len + y, x); return r;
}

inline Fix      operator << (Fix&  x, int y)
{
  _Fix rep = shift(x.rep, y); return rep;
}

inline Fix      operator >> (Fix&  x, int y)
{  
  _Fix rep = shift(x.rep, -y); return rep;
}

inline Fix Fix::operator <<= (int y)
{
  unique(); shift(rep, y, rep); return *this;
}

inline Fix  Fix::operator >>= (int y)
{
  unique(); shift(rep, -y, rep); return *this;
}



inline Fix abs(Fix  x)
{
  _Fix r = (compare(x.rep) >= 0 ? new_Fix(x.rep->len,x.rep) : negate(x.rep));
  return r;
}

inline int sgn(Fix& x)
{
  int a = compare(x.rep);
  return a == 0 ? 0 : (a > 0 ? 1 : -1);
}

inline int length(const Fix& x)
{
  return x.rep->len;
}

inline ostream& operator << (ostream& s, const Fix& y)
{
  if (s.opfx())
    y.printon(s);
  return s;
}

inline void	negate (Fix& x, Fix& r)
{
  negate(x.rep, r.rep);
}

inline void	add (Fix& x, Fix& y, Fix& r)
{
  add(x.rep, y.rep, r.rep);
}

inline void	subtract (Fix& x, Fix& y, Fix& r)
{
  subtract(x.rep, y.rep, r.rep);
}

inline void	multiply (Fix& x, Fix& y, Fix& r)
{
  multiply(x.rep, y.rep, r.rep);
}

inline void	divide (Fix& x, Fix& y, Fix& q, Fix& r)
{
  divide(x.rep, y.rep, q.rep, r.rep);
}

inline void	shift (Fix& x, int y, Fix& r)
{
  shift(x.rep, y, r.rep);
}



 
 



















 
 
























 



















#ident   "$Revision: 1.3 $"

 






















class Obstack
{
  struct _obstack_chunk
  {
    char*           limit;
    _obstack_chunk* prev;
    char            contents[4];
    char            ShitHead(char *, char *);
  };

protected:
  struct AllocQNode
  {
    void*  ptr;
    int    sz;
  };
  long	          chunksize;
  _obstack_chunk* chunk;
  char*	          objectbase;
  char*	          nextfree;
  char*	          chunklimit;
  int             alignmentmask;

  void  _free(void* obj);
  void  newchunk(int size);

public:
        Obstack(int size = 4080, int alignment = 4);  

        ~Obstack();

  void* base();
  void* next_free();
  int   alignment_mask();
  int   chunk_size();
  int   size();
  int   room();
  int   contains(void* p);       

  void  grow(const void* data, int size);
  void  grow(const void* data, int size, char terminator);
  void  grow(const char* s);
  void  grow(char c);
  void  grow_fast(char c);
  void  blank(int size);
  void  blank_fast(int size);

  void* finish();
  void* finish(char terminator);

  void* copy(const void* data, int size);
  void* copy(const void* data, int size, char terminator);
  void* copy(const char* s);
  void* copy(char c);
  void* alloc(int size);

  void  free(void* obj);
  void  shrink(int size = 1);  

  int   OK();                    
};


inline Obstack::~Obstack()
{
  _free(0); 
}

inline void* Obstack::base()
{
  return objectbase; 
}

inline void* Obstack::next_free()
{
  return nextfree; 
}

inline int Obstack::alignment_mask()
{
  return alignmentmask; 
}

inline int Obstack::chunk_size()
{
  return chunksize; 
}

inline int Obstack::size()
{
  return nextfree - objectbase; 
}

inline int Obstack::room()
{
  return chunklimit - nextfree; 
}

inline void Obstack:: grow(const void* data, int size)
{
  if (nextfree+size > chunklimit) 
    newchunk(size);
  memcpy(nextfree, data, size);
  nextfree += size; 
}

inline void Obstack:: grow(const void* data, int size, char terminator)
{
  if (nextfree+size+1 > chunklimit) 
    newchunk(size+1);
  memcpy(nextfree, data, size);
  nextfree += size; 
  *(nextfree)++ = terminator; 
}

inline void Obstack:: grow(const char* s)
{
  grow((const void*)s, strlen(s), 0); 
}

inline void Obstack:: grow(char c)
{
  if (nextfree+1 > chunklimit) 
    newchunk(1); 
  *(nextfree)++ = c; 
}

inline void Obstack:: blank(int size)
{
  if (nextfree+size > chunklimit) 
    newchunk(size);
  nextfree += size; 
}

inline void* Obstack::finish(char terminator)
{
  grow(terminator); 
  return finish(); 
}

inline void* Obstack::copy(const void* data, int size)
{
  grow (data, size);
  return finish(); 
}

inline void* Obstack::copy(const void* data, int size, char terminator)
{
  grow(data, size, terminator); 
  return finish(); 
}

inline void* Obstack::copy(const char* s)
{
  grow((const void*)s, strlen(s), 0); 
  return finish(); 
}

inline void* Obstack::copy(char c)
{
  grow(c);
  return finish(); 
}

inline void* Obstack::alloc(int size)
{
  blank(size);
  return finish(); 
}

inline void Obstack:: free(void* obj)     
{
  if (obj >= (void*)chunk && obj<(void*)chunklimit)
    nextfree = objectbase = (char *) obj;
  else 
    _free(obj); 
}

inline void Obstack:: grow_fast(char c)
{
  *(nextfree)++ = c; 
}

inline void Obstack:: blank_fast(int size)
{
  nextfree += size; 
}

inline void Obstack:: shrink(int size)  
{
  if (nextfree >= objectbase + size)
    nextfree -= size;
}



 
 






















 







class AllocRing
{

  struct AllocQNode
  {
    void*  ptr;
    int    sz;
  };

  AllocQNode* nodes;
  int         n;
  int         current;

  struct _obstack_chunk
  {
    char*           limit;
    _obstack_chunk* prev;
    char            contents[4];
    char            ShitHead(char *, char *);
  };
  int         find(void* p);

public:
  struct AllocQNode
  {
    void*  ptr;
    int    sz;
  };
              AllocRing(int max);
             ~AllocRing();
  void*       alloc(int size);
  int         contains(void* ptr);
  unsigned long int   contains(_FIX);
  void        clear();
  void        free(void* p);
  virtual inline void   foo(Fix);
  const extern static _Fix  bar(Fix);
  struct AllocQNode mumble(Fix);
  int         i,j(Fix),k;
  Fix         joe;
  virtual inline int   foo(Fix);
  friend class X;
  fart(((barf)));
  fart1(((int)));
};

typedef struct _obstack_chunk
{	
  char*           limit;
  _obstack_chunk* prev;
  char            contents[4];
  char            ShitHead(char *, char *);
} foobar;

typedef struct 
{	
  char*           limit;
  _obstack_chunk* prev;
  char            contents[4];
  char            ShitHead(char *, char *);
   const char* const step[3];
} foobar1;

 const char* const step[3] = {"left", "right", "hop"};



 

uint16 Fix_default_length = 16;
int    Fix_default_print_width = 8;

Fix_peh Fix_overflow_handler = Fix_overflow_saturate;

_Frep _Frep_0	= { 16, 1, 1, { 0 } };
_Frep _Frep_m1	= { 16, 1, 1, { 0x8000 } };
_Frep _Frep_quotient_bump = { 16, 1, 1, { 0x4000 } };

 

void default_Fix_error_handler(const char* msg)
{
  cerr << "Fix: " << msg << "\n";
  abort();
}

void default_Fix_range_error_handler(const char* msg)
{
  cerr << "Fix: range error in " << msg << "\n";
   
}

one_arg_error_handler_t 
  Fix_error_handler = default_Fix_error_handler,
  Fix_range_error_handler = default_Fix_range_error_handler;

one_arg_error_handler_t set_Fix_error_handler(one_arg_error_handler_t f)
{
  one_arg_error_handler_t old = Fix_error_handler;
  Fix_error_handler = f;
  return old;
}

one_arg_error_handler_t set_Fix_range_error_handler(one_arg_error_handler_t f)
{
  one_arg_error_handler_t old = Fix_range_error_handler;
  Fix_range_error_handler = f;
  return old;
}

void Fix::error(const char* msg)
{
  (*Fix_error_handler)(msg);
}

void Fix::range_error(const char* msg)
{
  (*Fix_range_error_handler)(msg);
}

 

static inline _Fix _new_Fix(uint16 len)
{
  int siz = (((uint32 )len + 15) >> 4);
  if (siz <= 0) siz = 1;
  unsigned int allocsiz = (sizeof(_Frep) + (siz - 1) * sizeof(uint16));
  _Fix z = (_Fix)(new char[allocsiz]);
  memset(z, 0, allocsiz);
  z->len = len;
  z->siz = siz;
  z->ref = 1;
  return z;
}

_Fix new_Fix(uint16 len)
{
  return _new_Fix(len);
}

_Fix new_Fix(uint16 len, const _Fix x)
{
  _Fix z = _new_Fix(len);
  return copy(x,z);
}

_Fix new_Fix(uint16 len, double d)
{
  _Fix z = _new_Fix(len);

  if ( d == 1.0  )
  {
    z->s[0] = 0x7fff;
    for ( int i=1; i < z->siz; i++ )
      z->s[i] = 0xffff;
  }
  else if ( d < -1.0  || d > 1.0  )
    (*Fix_range_error_handler)("declaration");
  else
  {
    if (d < 0)
      d += 2.0;
    d *= 32768;
    for ( int i=0; i < z->siz; i++ )
    {
      z->s[i] = (uint16 )d;
      d -= z->s[i];
      d *= 65536;
    }
    if ( d >= 32768 )
      z->s[z->siz-1]++;
  }
  mask(z);
  return z;
}

 

double value(const Fix& x)
{ 
  double d = 0.0;
  for ( int i=x.rep->siz-1; i >= 0; i-- )
  {
    d += x.rep->s[i];
    d *= 1.0/65536.0;
  }
  d *= 2.;
  return d < 1. ? d : d - 2.;
}

 

Integer mantissa(Fix& x)
{
  Integer a = 1, b=1;
  for ( int i=0; i < x.rep->siz; i++ )
  {
    a <<= 16;
    a += x.rep->s[i];
    b <<= 16;
  }
  return a-b;
}

 
  
inline static int docmp(uint16* x, uint16* y, int siz)
{
  int diff = (int16 )*x - (int16 )*y;
  while ( --siz && !diff )
    diff = (int32 )(uint32 )*++x - (int32 )(uint32 )*++y;
  return diff;
}

inline static int docmpz(uint16* x, int siz)
{
  while ( siz-- )
    if ( *x++ ) return 1;
  return 0;
}

int compare(const _Fix x, const _Fix y)
{
  if ( x->siz == y->siz )
    return docmp(x->s, y->s, x->siz);
  else
  {
    int r;
    _Fix longer, shorter;
    if ( x->siz > y->siz )
    {
      longer = x;
      shorter = y;
      r = 1;
    }
    else
    {
      longer = y;
      shorter = x;
      r = -1;
    }
    int diff = docmp(x->s, y->s, shorter->siz);
    if ( diff )
      return diff;
    else if ( docmpz(&longer->s[shorter->siz], longer->siz-shorter->siz) )
      return r;
    else
      return 0;
  }
}

 

_Fix add(_Fix x, _Fix y, _Fix r)
{
  uint16 xsign = x->s[0], ysign = y->s[0];
  _Fix longer, shorter;
  if ( x->len >= y->len )
    longer = x, shorter = y;
  else
    longer = y, shorter = x;
  if ( r == 0  )
    r = new_Fix(longer->len);
  for ( int i=r->siz-1; i >= longer->siz; i-- )
    r->s[i] = 0;
  for ( ; i >= shorter->siz; i-- )
    r->s[i] = longer->s[i];
  uint32 sum = 0, carry = 0;
  for ( ; i >= 0; i-- )
  {
    sum = carry + (uint32 )x->s[i] + (uint32 )y->s[i];
    carry = sum >> 16;
    r->s[i] = sum;
  }
  if ( (xsign ^ sum) & (ysign ^ sum) & 0x8000 )
    (*Fix_overflow_handler)(r);
  return r;
}

_Fix subtract(_Fix x, _Fix y, _Fix r)
{
  uint16 xsign = x->s[0], ysign = y->s[0];
  _Fix longer, shorter;
  if ( x->len >= y->len )
    longer = x, shorter = y;
  else
    longer = y, shorter = x;
  if ( r == 0  )
    r = new_Fix(longer->len);
  for ( int i=r->siz-1; i >= longer->siz; i-- )
    r->s[i] = 0;
  for ( ; i >= shorter->siz; i-- )
    r->s[i] = (longer == x ? x->s[i] : -y->s[i]);
  int16 carry = 0;
  uint32 sum = 0;
  for ( ; i >= 0; i-- )
  {
    sum = (int32 )carry + (uint32 )x->s[i] - (uint32 )y->s[i];
    carry = sum >> 16;
    r->s[i] = sum;
  }
  if ( (xsign ^ sum) & (~ysign ^ sum) & 0x8000 )
    (*Fix_overflow_handler)(r);
  return r;
}

_Fix multiply(_Fix x, _Fix y, _Fix r)
{
  if ( r == 0  )
    r = new_Fix(x->len + y->len);
  int xsign = x->s[0] & 0x8000,
    ysign = y->s[0] & 0x8000;
  Fix X(x->len), Y(y->len);
  if ( xsign )
    x = negate(x,X.rep);
  if ( ysign )
    y = negate(y,Y.rep);
  for ( int i=0; i < r->siz; i++ )
    r->s[i] = 0;
  for ( i=x->siz-1; i >= 0; i-- )
  {
    uint32 carry = 0;
    for ( int j=y->siz-1; j >= 0; j-- ) 
    {
      int k = i + j + 1;
      uint32 a = (uint32 )x->s[i] * (uint32 )y->s[j];
      uint32 b = ((a << 1) & 0xffff) + carry;
      if ( k < r->siz )
      {
	b += r->s[k];
        r->s[k] = b;
      }
      if ( k < (int)r->siz + 1 )
        carry = (a >> 15) + (b >> 16);
    }
    r->s[i] = carry;
  }
  if ( xsign != ysign )
    negate(r,r);
  return r;
}

_Fix multiply(_Fix x, int y, _Fix r)
{
  if ( y != (int16 )y )
    (*Fix_range_error_handler)("multiply by int -- int too large");
  if ( r == 0  )
    r = new_Fix(x->len);
  for ( int i=r->siz-1; i >= x->siz; i-- )
    r->s[i] = 0;
  int32 a, carry = 0;
  for ( ; i > 0; i-- )
  {
    a = (int32 )(uint32 )x->s[i] * y + carry;
    r->s[i] = a;
    carry = a >> 16;		 
  }
  a = (int32 )(int16 )x->s[0] * y + carry;
  r->s[0] = a;
  a &= 0xffff8000L;
  if ( a != 0xffff8000L && a != 0L ) {
    r->s[0] = 0x8000 ^ x->s[0] ^ y;
    (*Fix_overflow_handler)(r);
  }
  return r;
}

_Fix divide(_Fix x, _Fix y, _Fix q, _Fix r)
{
  int xsign = x->s[0] & 0x8000, 
    ysign = y->s[0] & 0x8000;
  if ( q == 0  )
    q = new_Fix(x->len);
  copy(&_Frep_0,q);
  if ( r == 0  )
    r = new_Fix(x->len + y->len - 1);
  if ( xsign )
    negate(x,r);
  else
    copy(x,r);
  Fix Y(y->len);
  y = ( ysign ? negate(y,Y.rep) : copy(y,Y.rep) );
  if ( !compare(y) )
    (*Fix_range_error_handler)("division -- division by zero");
  else if ( compare(x,y) >= 0 )
    if ( compare(x,y) == 0 && (xsign ^ ysign) != 0 )
    {
      copy(&_Frep_m1,q);
      copy(&_Frep_0,r);
    }
    else
      (*Fix_range_error_handler)("division");
  else
  {
    _Fix t;
    Fix S(r->len),
      W(q->len,&_Frep_quotient_bump);
    for ( int i=1; i < q->len; i++ )
    {
      shift(y,-1,y);
      subtract(r,y,S.rep);
      int s_status = compare(S.rep);
      if ( s_status == 0 ) 
      {
	t = r, r = S.rep, S.rep = t;
	break;
      }
      else if ( s_status > 0 )
      {
	t = r, r = S.rep, S.rep = t;
	add(q,W.rep,q);
      }
      shift(W.rep,-1,W.rep);
    }
    if ( xsign ^ ysign )
      negate(q,q);
  }
  return q;
}

_Fix shift(_Fix x, int y, _Fix r)
{
  if ( y == 0 )
    return x;
  else if ( r == 0  )
    r = new_Fix(x->len);

  int ay = abs((long) y),
    ayh = ay >> 4,
    ayl = ay & 0x0f;
  int xl, u, ilow, ihigh;
  uint16 *rs, *xsl, *xsr;

  if ( y > 0 )
  {
    rs = r->s;
    xsl = x->s + ayh;
    xsr = xsl + 1;
    xl = ayl;
    u = 1;
    ihigh = x->siz - ayh - 1;
    ilow = 0;
  }
  else
  {
    rs = &r->s[r->siz - 1];
    xsr = &x->s[r->siz - 1] - ayh;
    xsl = xsr - 1;
    xl = 16 - ayl;
    u = -1;
    ihigh = r->siz - ayh - 1;
    ilow = ihigh - x->siz;
  }

  int xr = 16 - xl;
  uint16 xrmask = 0xffffL >> xr;
  for ( int i=0; i < ilow; i++, rs+=u, xsl+=u, xsr+=u )
    *rs = 0;
  for ( ; i < ihigh; i++, rs+=u, xsl+=u, xsr+=u )
    *rs = (*xsl << xl) + ((*xsr >> xr) & xrmask);
  *rs = (y > 0 ? (*xsl << xl) : ((*xsr >> xr) & xrmask));
  rs += u;
  for ( ; ++i < r->siz; rs+=u )
    *rs = 0;
  return r;
}

_Fix negate(_Fix x, _Fix r)
{
  if ( r == 0  )
    r = new_Fix(x->len);
  uint32 carry = 1;
  for ( int i=r->siz-1; i >= x->siz; i-- )
    r->s[i] = 0;
  for ( ; i >= 0; i-- )
  {
    uint32 a = (uint16 )~x->s[i] + carry;	 
    r->s[i] = a;
    carry = a >> 16;
  }
  return r;
}

 

Fix atoF(const char* a, int len)
{
  return Fix(len,atof(a));
}

extern AllocRing _libgxx_fmtq;

void Fix::printon(ostream& s, int width) const
{
  double val = value(*this);
  int old_precision = s.precision(width-3);
  long old_flags = s.setf(ios::fixed, ios::fixed|ios::scientific);
  if (val >= 0)
      s << ' ';
  s.width(width-2);
  s << val;
  s.precision(old_precision);
  s.flags(old_flags);
}

char* Ftoa(Fix& x, int width)
{
  int wrksiz = width + 2;
  char *fmtbase = (char *) _libgxx_fmtq.alloc(wrksiz);
  ostrstream stream(fmtbase, wrksiz);
  
  x.printon(stream, width);
  stream << ends;
  return fmtbase;
}

extern Obstack _libgxx_io_ob;

Fix Fix::operator %= (int y)
{
  Fix r((int )rep->len + y, *this); return *this = r;
}

istream& operator >> (istream& s, Fix& y)
{
  int got_one = 0;
  if (!s.ipfx(0))
  {
    s.clear(ios::failbit|s.rdstate());  
    return s;
  }

  char sign = 0, point = 0;
  char ch;
  s >> ws;
  if (!s.good())
  {
    s.clear(ios::failbit|s.rdstate());
    return s;
  }
  while (s.get(ch))
  {
    if (ch == '-')
    {
      if (sign == 0)
      {
        sign = 1;
        _libgxx_io_ob.grow(ch);
      }
      else
        break;
    }
    if (ch == '.')
    {
      if (point == 0)
      {
        point = 1;
        _libgxx_io_ob.grow(ch);
      }
      else
        break;
    }
    else if (ch >= '0' && ch <= '9')
    {
      got_one = 1;
      _libgxx_io_ob.grow(ch);
    }
    else
      break;
  }
  char * p = (char*)(_libgxx_io_ob.finish(0));
  if (s.good())
    s.putback(ch);
  if (!got_one)
    s.clear(ios::failbit|s.rdstate());
  else
    y = atoF(p);
  _libgxx_io_ob.free(p);
  return s;
}

void show(Fix& x)
{
  cout << "len = " << x.rep->len << "\n";
  cout << "siz = " << x.rep->siz << "\n";
  cout << "ref = " << x.rep->ref << "\n";
  cout << "man = ";

  int old_flags = cout.setf(ios::hex, ios::hex|ios::dec|ios::oct);
  cout.width(4*x.rep->siz);
  cout << mantissa(x);
  cout.setf(old_flags, ios::hex|ios::dec|ios::oct);

  cout << "\n";
  cout << "val = " << value(x) << "\n";
}

 

Fix_peh set_overflow_handler(Fix_peh new_handler) {
  Fix_peh old_handler = Fix_overflow_handler;
  Fix_overflow_handler = new_handler;
  return old_handler;
}

int Fix_set_default_length(int newlen)
{
  uint16 oldlen = Fix_default_length;
  if ( newlen < 1  || newlen > 65535  )
    (*Fix_error_handler)("illegal length in Fix_set_default_length");
  Fix_default_length = newlen;
  return oldlen;
}

 

void Fix_overflow_saturate(_Fix& r) {
  if ( (int16 )r->s[0] > 0 ) 
  {
    r->s[0] = 0x8000;
    for ( int i=1; i < r->siz; i++ )
      r->s[i] = 0;
  }
  else
  {
    r->s[0] = 0x7fff;
    for ( int i = 1; i < (int)r->siz; i++ )
      r->s[i] = 0xffff;
    mask(r);
  }
}

void Fix_overflow_wrap(_Fix&) {}

void Fix_overflow_warning_saturate(_Fix& r) {
  Fix_overflow_warning(r);
  Fix_overflow_saturate(r);
}

void Fix_overflow_warning(_Fix&) {
  cerr << "Fix: overflow warning\n"; 
}

void Fix_overflow_error(_Fix&) {
  cerr << "Fix: overflow error\n"; 
  abort();
}

