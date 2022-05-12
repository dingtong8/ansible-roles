# coding=utf-8
# version: python2.7
# author: dingtong
# date: 2022-05-12
# 脚本描述: ansible过滤器插件
# 脚本使用: ansible.cnf打开filter_plugins，将此脚本放在filter_plugins目录下
from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils.six import iteritems
import json
import datetime


def get_log_data(data):
    """
    Get the json data of check_result from hostvars and analyze it.
    :param data: hostvars
    :return: dict
    """
    item = {
        'failed_ssh_item': {}
    }
    item = {
        'time': '',
        'failed_ssh_item': {}
    }

    for host, value in iteritems(data):
        # {'stderr_lines': [u'Shared connection to 192.168.31.222 closed.'], 'stdout': u'{ "log_ssh": { "failed_ssh": " 1 192.168.31.160" } }\r\n', 'changed': True, 'failed': False, 'stderr': u'Shared connection to 192.168.31.222 closed.\r\n', 'rc': 0, 'stdout_lines': [u'{ "log_ssh": { "failed_ssh": " 1 192.168.31.160" } }']}
        result = value.get('check_result')
        if result:
            if 'msg' in result:
                item['error_item'][host] = {'msg': result['msg']}
                continue
            # { "log_ssh": { "failed_ssh": " 1 192.168.31.160" } }
            stdout = result.get('stdout')
            try:
                # {u'log_ssh': {u'failed_ssh': u' 1 192.168.31.160 2 192.168.31.162'}}
                info = json.loads(stdout)
                failed_ssh = info['log_ssh']['failed_ssh'].strip().encode(encoding='utf-8')
                failed_ssh = '{' + failed_ssh + '}'
                info = eval(failed_ssh)
            except Exception as e:
                item['error_item'][host] = {'msg': stdout}
                continue

            # info = {'192.168.31.79': '5', '192.168.31.75': '1', '192.168.31.74': '1', '192.168.31.76': '1'}
            item['failed_ssh_item'][host] = info

    # import pydevd_pycharm
    # pydevd_pycharm.settrace('192.168.77.1', port=8888, stdoutToServer=True, stderrToServer=True)

    # summary
    item['time'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # sorted
    item['failed_ssh_item'] = sorted(iteritems(item['failed_ssh_item']))

    return item


class FilterModule(object):
    """Filters for working with output from hostvars check_result"""

    def filters(self):
        return {
            'get_log_data': get_log_data
        }
