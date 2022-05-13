import datetime

item = {
    'time': '',
    'failed_ssh_item': {}
}
info = {'192.168.31.79': '5', '192.168.31.75': '1', '192.168.31.74': '1', '192.168.31.76': '1'}
host = '192.168.31.222'
item['failed_ssh_item'][host] = info
item['time'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')



value = {'192.168.31.71': '1', '192.168.31.73': '1', '192.168.31.72': '1', '192.168.31.75': '1', '192.168.31.74': '1', '192.168.31.76': '1', '192.168.31.79': '5', '192.168.31.160': '1'}
for k in value:
    print k, value.get(k)


