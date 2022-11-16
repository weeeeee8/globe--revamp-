local import = loadstring(game:HttpGet('https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/src/env/import.lua'), 'import.lua')()

import:CreateDirectory('env/lib')
import:CreateDirectory('env/util')
import:CreateDirectory('scripts')
import('env/lib/environment')(import) -- start up our base environment