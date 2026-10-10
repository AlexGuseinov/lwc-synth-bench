MASK = 0xFFFFFFFF
def rotr(x, r): return ((x >> r) | (x << (32 - r))) & MASK
def rotl(x, r): return ((x << r) | (x >> (32 - r))) & MASK

# ---------------- SPECK 64/128 ----------------
def speck_ks(kw):  # kw most-significant-first: (l2,l1,l0,k0)
    R=27; m=4
    k=[0]*R; l=[0]*(R+m-1)
    k[0]=kw[3]; l[0]=kw[2]; l[1]=kw[1]; l[2]=kw[0]
    for i in range(R-1):
        l[i+m-1]=(((rotr(l[i],8)+k[i])&MASK)^i)&MASK
        k[i+1]=rotl(k[i],3)^l[i+m-1]
    return k
def speck_enc(x,y,k):
    for i in range(27):
        x=((rotr(x,8)+y)&MASK)^k[i]
        y=rotl(y,3)^x
    return x,y

skey=[0x1b1a1918,0x13121110,0x0b0a0908,0x03020100]
sx,sy=0x3b726574,0x7475432d
cx,cy=speck_enc(sx,sy,speck_ks(skey))
print("SPECK64/128 ct = %08x %08x  expect 8c6fa548 454e028b  %s"%(cx,cy,"OK" if (cx,cy)==(0x8c6fa548,0x454e028b) else "FAIL"))

# ---------------- SIMON 64/128 ----------------
Z={
 0:"11111010001001010110000111001101111101000100101011000011100110",
 1:"10001110111110010011000010110101000111011111001001100001011010",
 2:"10101111011100000011010010011000101000010001111110010110110011",
 3:"11011011101011000110010111100000010010001010011100110100001111",
 4:"11010001111001101011011000100000010111000011001010010011101111",
}
def simon_ks(kw, zsel):
    R=44; m=4; c=0xFFFFFFFC; z=[int(b) for b in Z[zsel]]
    k=[0]*R
    for i in range(m): k[i]=kw[m-1-i]   # k0 = lowest = kw[3]
    for i in range(m,R):
        tmp=rotr(k[i-1],3)
        if m==4: tmp^=k[i-3]
        tmp^= rotr(tmp,1)
        k[i]=k[i-m]^tmp^z[(i-m)%62]^c   # c ^ k = ~k ^ 3
        k[i]&=MASK
    return k
def simon_enc(x,y,k):
    for i in range(44):
        t=x
        x=y^(rotl(x,1)&rotl(x,8))^rotl(x,2)^k[i]
        y=t
    return x,y

mkey=[0x1b1a1918,0x13121110,0x0b0a0908,0x03020100]
mx,my=0x656b696c,0x20646e75
for zsel in range(5):
    cx,cy=simon_enc(mx,my,simon_ks(mkey,zsel))
    ok="OK" if (cx,cy)==(0x44c8fc20,0xb9dfa07a) else ""
    print("SIMON z%d ct = %08x %08x  %s"%(zsel,cx,cy,ok))
