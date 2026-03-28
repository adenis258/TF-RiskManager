$content = [System.IO.File]::ReadAllText('TF_RiskManager_v15_5.mq5')
$s = 'void RecalculateBuffers()'
$s_idx = $content.IndexOf($s)
$s_idx = $content.IndexOf($s, $s_idx + 1)
$e = '//| Check Trading Conditions'
$e_idx = $content.IndexOf($e)
$e_idx = $content.LastIndexOf('//+', $e_idx)
$p1 = $content.Substring(0, $s_idx)
$p2 = $content.Substring($e_idx)
$r = [System.IO.File]::ReadAllText('recalc.txt')
[System.IO.File]::WriteAllText('TF_RiskManager_v15_5.mq5', $p1 + $r + $p2)
