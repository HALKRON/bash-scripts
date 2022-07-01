<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        .recovered {
            color: green;
        }
        .critical {
            color: red;
        }
        .warning {
            color: orange;
        }
        .alert_title {
            text-align: center;
        }
        .graphs {
            display: block;
            max-width: 100%;
        }
        .tbl_info {
            border: 2px #808080 solid;
        }
        .tbl_header {
            border: 2px #bc8f8f solid;
            background-color: #bc8f8f;
            color: #ffffff;
        }
        .btn_dev {
            background-color: #bc8f8f;
            font-size: medium;
            font-weight: bold;
            color: white;
            border: 4px solid #bc8f8f;
            padding: 10px 24px;
        }
        table {
            width: 100%;
        }
        td {
            padding: 2px;
        }
        col {
            background-color: #d8bdbd;
        }
    </style>
</head>
<body>
    <div class="alert_title">
        @if ($alert->state == 0)
        <h1 class="recovered">RECOVERED</h1>
        <h2 class="recovered">Time Taken: {{ $alert->elapsed }}</h2>
        @endif
        @if ($alert->severity == critical)
        <h1 class="critical">CRITICAL</h1>
        <h2 class="critical">{{ $alert->name }}</h2>
        @endif
        @if ($alert->severity == warning)
        <h1 class="warning">WARNING</h1>
        <h2 class="warning">{{ $alert->name }}</h2>
        @endif
        <h3><a href="http://SERVER_IP/device/{{ $alert->device_id }}"><button class="btn_dev" type="button">Go To Device</button></a></h3>
    </div>
    <div>
        <table class="tbl_info">
            <colgroup>
                <col>
            </colgroup>
            <tr>
                <td class="tbl_info">Display Name</td>
                <td class="tbl_info">@if ($alert->display) {{ $alert->display }} @else {{ $alert->sysName }} @endif</td>
            </tr>
            <tr>
                <td class="tbl_info">OS</td>
                <td class="tbl_info" style="text-transform: capitalize;">{{ $alert->os }}</td>
            </tr>
            <tr>
                <td class="tbl_info">Type</td>
                <td class="tbl_info" style="text-transform: capitalize;">{{ $alert->type }}</td>
            </tr>
            <tr>
                <td class="tbl_info">IP Address / DNS</td>
                <td class="tbl_info">{{ $alert->hostname }}</td>
            </tr>
            <tr>
                <td class="tbl_info">Location</td>
                <td class="tbl_info">{{ $alert->location }}</td>
            </tr>
            <tr>
                <td class="tbl_info">Timestamp</td>
                <td class="tbl_info">{{ $alert->timestamp }}</td>
            </tr>
            <tr>
                <td class="tbl_info" colspan="2"><img class="graphs" src="http://SERVER_IP/graph.php?type=device_processor&from=end-72h&legend=no&lazy_w=804&device={{ $alert->device_id }}&height=300&width=800" alt="Device Processor" title="Device Processor"></td>
            </tr>
            <tr>
                <td class="tbl_info" colspan="2"><img class="graphs" src="http://SERVER_IP/graph.php?type=device_mempool&from=end-72h&legend=no&lazy_w=804&device={{ $alert->device_id }}&height=300&width=800" alt="Device Memory" title="Device Memory"></td>
            </tr>
            <tr>
                <td class="tbl_info" colspan="2"><img class="graphs" src="http://SERVER_IP/graph.php?type=device_bits&from=end-72h&legend=no&lazy_w=804&device={{ $alert->device_id }}&height=300&width=800" alt="Device Traffic" title="Device Traffic"></td>
            </tr>
        </table>
        <br>
    </div>

    <div>
        @yield('content')
    </div>
</body>
</html>
