"""Six real Main/UI processes, at least 120 monotonic seconds per preset, then restarts."""
import argparse, concurrent.futures, os, shutil, subprocess, tempfile
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot',default='godot')
parser.add_argument('--seconds',type=float,default=120)
args=parser.parse_args()
if args.seconds < 120: raise SystemExit('The release regression requires at least 120 real seconds.')
root=Path(__file__).resolve().parents[1]
engine=shutil.which(args.godot) or args.godot
logs=root/'builds/reconstruction-audit/settings'
logs.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='Tribes settings lifecycle ') as directory:
    base=Path(directory)
    def run(preset):
        env=os.environ.copy()
        for key,child in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]: env[key]=str(base/str(preset)/child)
        for phase in ['initial','restart']:
            command=[engine,'--headless','--path',str(root),'--script','res://Tests/test_settings_lifecycle.gd','--',f'--qa-preset={preset}',f'--qa-seconds={args.seconds}',f'--save-dir={base/str(preset)/"world"}']
            if phase=='restart': command.append('--qa-restore')
            output=subprocess.run(command,env=env,cwd=root,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=args.seconds+90)
            (logs/f'preset-{preset}-{phase}.log').write_text(output.stdout)
            marker='SETTINGS_RESTART_PASS' if phase=='restart' else 'SETTINGS_LIFECYCLE_PASS'
            if output.returncode or marker not in output.stdout or 'ERROR:' in output.stdout or 'failed=true' in output.stdout: raise RuntimeError(f'Preset {preset} {phase}: '+output.stdout)
        return preset
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for preset in pool.map(run,range(6)): print('SETTINGS_PRESET_PASS',preset,flush=True)
print('SETTINGS_LIFECYCLE_PASS presets=6 real_seconds_per_preset>=120 restarts=6')
