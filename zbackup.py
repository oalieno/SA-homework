#!/usr/bin/env python
import sys
import getopt
import random
import daemon
import subprocess

NORMAL = '\033[0m'
INFO = '\033[92m' + " [INFO] "
ERROR = '\033[91m' + "[ERROR] "

MONTH = {"Jan":1,"Feb":2,"Mar":3,"Apr":4,"May":5,"Jun":6,"Jul":7,"Aug":8,"Sep":9,"Oct":10,"Nov":11,"Dec":12}

def Usage():
    print INFO + "Usage : " + NORMAL
    print INFO + "./zbackup" + NORMAL
    print INFO + "--list   [target_dataset [ID]]" + NORMAL
    print INFO + "--delete [target_dataset [rotation_count]]" + NORMAL
    print INFO + "--daemon -d" + NORMAL
    print INFO + "--config -c" + NORMAL

def Command(cmd):
    p = subprocess.Popen(cmd,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    return p.stdout.read().strip()

def Status(target):
    result = Command("zfs list -t snapshot -o name,zbackup:zbackup,zbackup:time").split('\n')
    status = []
    for i in xrange(1,len(result)):
        now = result[i].split()
        if target == None or now[1] == "true" and now[0][:now[0].find('@')] == target:
            status.append(now)
    return status

def Create(args):
    TIMENOW = Command("date").split()
    TIMENOW = TIMENOW[5] + '-' + str(MONTH[TIMENOW[1]]) + '-' + TIMENOW[2] + " " + TIMENOW[3]
    while True:
        result = Command("sudo zfs snapshot -o zbackup:zbackup=true -o zbackup:time=\"" + TIMENOW + "\" " + args[0] + "@" + str(random.randint(0,999999)).zfill(6))
        if "cannot create snapshot" not in result:
            break
    rotation = 20
    if len(args) == 2:
        rotation = int(args[1])
    status = Status(args[0])
    for i in xrange(len(status)-rotation):
        Command("sudo zfs destroy " + status[i][0])

def List(args):
    if len(args) == 0:
        status = Status(None)
    else:
        status = Status(args[0])
    ID = 1
    print "%-5s%-15s%s" % ("ID","Dataset","Time")
    for now in status:
        if len(args) <= 1 or args[1] == str(ID):
            print "%-5d%-15s%s" % (ID,now[0][:now[0].find('@')],now[2] + ' ' + now[3])
        ID += 1

def Delete(args):
    if len(args) == 0:
        status = Status(None)
    else:
        status = Status(args[0])
    ID = 1
    for now in status:
        if len(args) <= 1 or args[1] == str(ID):
            Command("sudo zfs destroy " + now[0])
        ID += 1

def Daemon():
    pass

def Config(path):
    print path

try:
    opts, args = getopt.getopt(sys.argv[1:],"dc:",["list","delete","daemon","config="])
    if len(opts) == 0 and len(args) == 0 or len(opts) > 2:
        raise Exception()
    elif len(args) > 2 or len(args) == 2 and not args[1].isdigit():
        raise Exception()
except getopt.GetoptError as error:
    print ERROR + error + NORMAL
    Usage()
    sys.exit(2)
except Exception as error:
    print ERROR + "Format is incorrect" + NORMAL
    Usage()
    sys.exit(2)

if len(opts) == 0:
    Create(args)
else:
    for o,a in opts:
        if o == "--list":
            List(args)
        elif o == "--delete":
            Delete(args)
        elif o in ("-d","--daemon"):
            with daemon.DaemonContext():
                Daemon()
        elif o in ("-c","--config"):
            Config(a)
