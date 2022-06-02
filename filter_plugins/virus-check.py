# coding=utf-8
# version: python2.7
# author: dingtong
# date: 2022-06-02
# 脚本描述: ansible过滤器插件
# 脚本使用: ansible.cnf打开filter_plugins，将此脚本放在filter_plugins目录下
from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils.six import iteritems
import json
import datetime


def get_dir_virus_check_data(data):
    """
    Get the json data of check_result from hostvars and analyze it.
    :param data: hostvars
    :return: dict
    """
    item = {
        'time': '',
        'dir_virus_item': {}
    }

    for host, value in iteritems(data):
        #
        result = value.get('check_result')
        if result:
            if 'msg' in result:
                item['error_item'][host] = {'msg': result['msg']}
                continue
        # { "dir_ls_virus": { "tmp_ls": "'syncthing.log':'1', 'supervisord.log':'1',", "opt_ls": "'tty':'1', 'shm':'1', 'ptmx':'1'," } }
            stdout = result.get('stdout')
            #print('stdout', stdout)
            try:
                # {u'log_mysql': {u'failed_mysql': u' 1 192.168.31.160 2 192.168.31.162'}}
                info = json.loads(stdout)
                #print('info', info)
                # {u'opt_ls': u"'ptmx':'1',", u'tmp_ls': u"'syncthing.log':'1', 'jruby-951':'1', 'jruby-29212':'1',"}
                virus = info['dir_ls_virus']#.encode(encoding='utf-8')     # 此处和shell取值脚本参数一致
                #print('virus', virus)
                # failed_mysql = '{' + failed_mysql + '}'
                # info = eval(failed_mysql)
            except Exception as e:
                item['error_item'][host] = {'msg': stdout}
                continue

            # info = {'192.168.31.79': '5', '192.168.31.75': '1', '192.168.31.74': '1', '192.168.31.76': '1'}
            item['dir_virus_item'][host] = virus

    # import pydevd_pycharm
    # pydevd_pycharm.settrace('192.168.77.1', port=8888, stdoutToServer=True, stderrToServer=True)

    # summary
    item['time'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # sorted
    item['dir_virus_item'] = sorted(iteritems(item['dir_virus_item']))
    print(item)

    return item


class FilterModule(object):
    """Filters for working with output from hostvars check_result"""

    def filters(self):
        return {
            'get_dir_virus_check_data': get_dir_virus_check_data
        }