#!/usr/bin/env python3
import sys, locale, datetime as DT
locale.setlocale(locale.LC_ALL, "")
#lc_time = locale.getlocale(locale.LC_TIME)[0]
#locale.setlocale(locale.LC_ALL, lc_time + ".UTF-8")
for line in sys.stdin:
    line = line.strip()
    print(DT.datetime.strptime(line, '%a %b %d %H:%M:%S %Z %Y'))
