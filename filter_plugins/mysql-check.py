# coding=utf-8
# version: python2.7
# author: dingtong
# date: 2022-05-20
# 脚本描述: ansible过滤器插件
# 脚本使用: ansible.cnf打开filter_plugins，将此脚本放在filter_plugins目录下
from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils.six import iteritems
import json
import datetime


def get_mysql_check_data(data):
    """
    Get the json data of check_result from hostvars and analyze it.
    :param data: hostvars
    :return: dict
    """
    item = {
        'time': '',
        'failed_mysql_item': {}
    }

    for host, value in iteritems(data):
        # {'stderr_lines': [u'Shared connection to 192.168.31.222 closed.'], 'stdout': u'{ "log_mysql": { "failed_mysql": " 1 192.168.31.160" } }\r\n', 'changed': True, 'failed': False, 'stderr': u'Shared connection to 192.168.31.222 closed.\r\n', 'rc': 0, 'stdout_lines': [u'{ "log_mysql": { "failed_mysql": " 1 192.168.31.160" } }']}
        result = value.get('check_result')
        if result:
            if 'msg' in result:
                item['error_item'][host] = {'msg': result['msg']}
                continue
            # { "log_mysql": { "failed_mysql": " 1 192.168.31.160" } }
            stdout = result.get('stdout')
            print(stdout)
            try:
                # {u'log_mysql': {u'failed_mysql': u' 1 192.168.31.160 2 192.168.31.162'}}
                info = json.loads(stdout)
                failed_mysql = info['log_mysql']['failed_mysql'].strip().encode(encoding='utf-8')     # 此处和shell取值脚本参数一致
                failed_mysql = '{' + failed_mysql + '}'
                info = eval(failed_mysql)
            except Exception as e:
                item['error_item'][host] = {'msg': stdout}
                continue

            # info = {'192.168.31.79': '5', '192.168.31.75': '1', '192.168.31.74': '1', '192.168.31.76': '1'}
            item['failed_mysql_item'][host] = info

    # import pydevd_pycharm
    # pydevd_pycharm.settrace('192.168.77.1', port=8888, stdoutToServer=True, stderrToServer=True)

    # summary
    item['time'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # sorted
    item['failed_mysql_item'] = sorted(iteritems(item['failed_mysql_item']))

    return item


class FilterModule(object):
    """Filters for working with output from hostvars check_result"""

    def filters(self):
        return {
            'get_mysql_check_data': get_mysql_check_data
        }
