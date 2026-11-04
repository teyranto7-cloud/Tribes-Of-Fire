"""Run a real Godot viewport test; optional Linux Xorg dummy display for cloud QA."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--script',required=True)
    parser.add_argument('--log',type=Path,required=True)
    parser.add_argument('--virtual-display',action='store_true')
    parser.add_argument('--timeout',type=int,default=480)
    args=parser.parse_args()
    args.log.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='tribes-render-') as temp:
        folder=Path(temp);env=os.environ.copy();server=None
        for key in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']:env[key]=str(folder/key)
        with args.log.open('w') as output, (folder/'xorg.log').open('w') as xlog:
            try:
                if args.virtual_display:
                    number=next(i for i in range(96,120) if not Path(f'/tmp/.X{i}-lock').exists())
                    configuration=folder/'xorg.conf'
                    configuration.write_text('''Section "ServerFlags"
Option "AutoAddDevices" "false"
Option "AutoEnableDevices" "false"
EndSection
Section "Device"
Identifier "DummyGPU"
Driver "dummy"
VideoRam 65536
EndSection
Section "Monitor"
Identifier "DummyMonitor"
HorizSync 15.0-200.0
VertRefresh 15.0-120.0
Modeline "1920x1080" 148.50 1920 2008 2052 2200 1080 1084 1089 1125
Modeline "1280x720" 74.50 1280 1344 1472 1664 720 723 728 748
EndSection
Section "Screen"
Identifier "DummyScreen"
Device "DummyGPU"
Monitor "DummyMonitor"
DefaultDepth 24
SubSection "Display"
Depth 24
Modes "1920x1080" "1280x720"
EndSubSection
EndSection
''')
                    server=subprocess.Popen(['Xorg',f':{number}','-config',str(configuration),'-logfile',str(folder/'xorg-detail.log'),'-noreset','-nolisten','tcp','-ac'],stdout=xlog,stderr=subprocess.STDOUT)
                    for _ in range(60):
                        if server.poll() is not None:raise RuntimeError('Virtual display failed: '+(folder/'xorg.log').read_text())
                        if Path(f'/tmp/.X11-unix/X{number}').exists():break
                        time.sleep(.1)
                    env['DISPLAY']=f':{number}'
                result=subprocess.run(['godot','--path',str(ROOT),'--audio-driver','Dummy','--script',args.script],cwd=ROOT,env=env,stdout=output,stderr=subprocess.STDOUT,timeout=args.timeout)
                if result.returncode:raise SystemExit(result.returncode)
            finally:
                if server is not None:server.terminate();server.wait(timeout=5)
    content=args.log.read_text()
    if any(marker in content for marker in ['SCRIPT ERROR:','\nERROR:','instances leaked']):raise SystemExit('Runtime error in '+str(args.log))
    print('RENDER_RUN_PASS',args.script,args.log)

if __name__=='__main__':main()
