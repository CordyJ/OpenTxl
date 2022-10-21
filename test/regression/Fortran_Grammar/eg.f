        subroutine cedge(nv,nt,nb,itnode,ibndry,
     1      itedge,vx,vy,list,iflag)
c
            integer itnode(4,*),ibndry(5,*),itedge(3,*),list(*)
            real vx(*),vy(*)
c
c       initialize
c
        iflag=0
        do 10 i=1,nv
   10       list(i)=0
        llist=nv+nb+3*nt
        iptr=nv+1
        do 20 i=iptr,llist,2
   20       list(i)=i+2
        list(llist-1)=0
        list(llist-2)=0
c
c       first find adjacent triangles
c
        do 60 i=1,nt
            do 50 j=1,3
                j1=(5-j)/2
                j2=6-j-j1
                imax=max0(itnode(j1,i),itnode(j2,i))
                imin=min0(itnode(j1,i),itnode(j2,i))
                kold=imin
   40           k=list(kold)
                if(k.le.0) then
c
c       add triangle i, edge j to list
c
                    if(iptr.le.0) go to 180
                    list(kold)=iptr
                    ii=iptr
                    iptr=list(iptr)
                    list(ii)=0
                    list(ii+1)=j+4*i
                else
c
c       check for a common edge
c
                    ii=list(k+1)/4
                    jj=list(k+1)-4*ii
                    j1=(5-jj)/2
                    j2=6-jj-j1
                    iimax=max0(itnode(j1,ii),itnode(j2,ii))
                    if(imax.eq.iimax) then
                        itedge(j,i)=ii
                        itedge(jj,ii)=i
                        list(kold)=list(k)
                        list(k)=iptr
                        iptr=k
c
c       check geometry
c
                        qi=geom(itnode(j,i),imin,imax,vx,vy)
                        qk=geom(itnode(jj,ii),imin,imax,vx,vy)
                        if(qi*qk.ge.0.0e0) go to 190
                    else
                        kold=k
                        go to 40
                    endif
                endif
   50       continue
   60   continue
c
c       match boundary data in ibndry
c
        do 80 i=1,nb
            kold=min0(ibndry(1,i),ibndry(2,i))
            imax=max0(ibndry(1,i),ibndry(2,i))
   70       k=list(kold)
            if(k.le.0) go to 170
            ii=list(k+1)/4
            jj=list(k+1)-4*ii
            j1=(5-jj)/2
            j2=6-jj-j1
            iimax=max0(itnode(j1,ii),itnode(j2,ii))
            if(imax.eq.iimax) then
                itedge(jj,ii)=-i
                list(kold)=list(k)
                list(k)=iptr
                iptr=k
            else
                kold=k
                go to 70
            endif
   80   continue
c
c       check for left over edges
c
        do 90 i=1,nv
            if(list(i).gt.0) go to 160
   90   continue
        return
c
c       error return
c
  160   iflag=-160
        return
  170   iflag=-170
        return
  180   iflag=-180
        return
  190   iflag=-190
        return
        end

