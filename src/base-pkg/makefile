#default target
d base

# base target
t base,:

w WARN_VERBOSE

c rm /tmp/syslog && touch /tmp/syslog
c rm /dev/hda/CFSDATA
c yapi -Syc
c makeyap
c sync

end-target;

# Submit target, default to all packages
t submit,base:

v :PKGNAME
c echo ;Package name for your base.yap?
r :PKGNAME

v :USR
c echo ;Username:
r :USR

v :USRPWD
c echo ;Password:
r :USRPWD

l USR,USRPWD
vc pkgsend auth $;$
l PKGNAME
vc pkgsend send base.yap $ vote-community

end-target;

#Clean target
t clean,:

c rm base.yap

end-target;

#redo build
t rebuild,clean,base:
end-target;
