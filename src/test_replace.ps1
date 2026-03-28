$f = " TF_RiskManager_v15_5.mq5\
$d = [IO.File]::ReadAllText($f)
$r = [IO.File]::ReadAllText(\recalc.txt\)
$p = '(?s)void RecalculateBuffers\(\)\r?\n\{.*?tf_confirm=0;\}\r?\n\}'
$d = [Text.RegularExpressions.Regex]::Replace($d, $p, $r)
[IO.File]::WriteAllText($f, $d)
