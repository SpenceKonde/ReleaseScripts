md C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore
copy C:\Users\Spence\Documents\Arduino\hardware\megaTinyCore\*.md C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore
robocopy C:\Users\Spence\Documents\Arduino\hardware\megaTinyCore\megaavr C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore /E
del C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\extras\*.png
del C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\extras\*.gif
del C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\extras\*.jpg
rmdir /Q /S C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\tools\python3
rmdir /Q /S C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\tools\libs
del C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\tools\prog.py
robocopy C:\Users\Spence\Documents\Electronics\CorePacking\tools_modern\ C:\Users\Spence\Documents\Electronics\CorePacking\megaTinyCore\tools /E
