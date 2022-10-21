
class Integer
{
public:
  friend void     xor(long x,  Integer& dest);
  int             fits_in_long() const { return Iislong(rep); } ; 
};
