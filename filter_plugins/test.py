import json

a = {'dir_virus_item': [(u'192.168.31.222', {u'opt_ls': u"'ptmx',",
                                             u'tmp_ls': u"'hsperfdata_root', 'jruby-17977', 'jruby-22072', 'jruby-29212', 'jruby-951', 'syncthing.log',"}),
                        (u'192.168.31.223', {u'opt_ls': u"'ptmx', 'shm', 'tty',",
                                             u'tmp_ls': u"'mysql-report-2022-06-02.html', 'supervisord.log', 'syncthing.log', 'virus-report-2022-06-02.html',"})],
}

for k, v in a.items():
    for i in v:
        for m, n in i[1].items():
            for l in json.dumps(n):
                print(l)


