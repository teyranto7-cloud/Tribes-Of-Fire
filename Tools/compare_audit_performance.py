from pathlib import Path
import argparse,json,os,shutil,subprocess,tempfile
parser=argparse.ArgumentParser()
parser.add_argument("--baseline",default="d77dbc1")
parser.add_argument("--output",default="builds/audit/performance")
parser.add_argument("--warmup-seconds",type=float,default=1)
parser.add_argument("--sample-seconds",type=float,default=4)
args=parser.parse_args()
bench_env=os.environ.copy();bench_env["TRIBES_BENCHMARK_WARMUP"]=str(args.warmup_seconds);bench_env["TRIBES_BENCHMARK_DURATION"]=str(args.sample_seconds)
root=Path(__file__).resolve().parents[1];out=root/args.output;out.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='tribes-audit-baseline-') as temp:
 base=Path(temp)/'baseline';subprocess.run(['git','worktree','add','--quiet','--detach',str(base),args.baseline],cwd=root,check=True)
 try:
  shutil.copy2(root/'Tools/audit_benchmark.gd',base/'Tools/audit_benchmark.gd')
  env=os.environ.copy()
  for key in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']:env[key]=str(Path(temp)/key)
  with (out/'baseline-import.log').open('w') as log:subprocess.run(['godot','--headless','--path',str(base),'--editor','--import'],cwd=base,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=90)
  reports={}
  for name,project in [('before',base),('after',root)]:
   subprocess.run(['python3',str(project/'Tools/render_check.py'),'--script','res://Tools/audit_benchmark.gd','--log',str(out/f'{name}.log'),'--virtual-display','--timeout','300'],cwd=project,env=bench_env,check=True)
   data=json.loads((project/'builds/audit/performance.json').read_text());reports[name]=data
   (out/f'{name}.json').write_text(json.dumps(data,indent=2)+'\n');print('PERFORMANCE_SAMPLE_COMPLETE',name,flush=True)
  comparisons=[]
  for before,after in zip(reports['before']['samples'],reports['after']['samples']):
   assert before['scene']==after['scene']
   comparisons.append({'scene':before['scene'],'fps_before':before['fps'],'fps_after':after['fps'],'p95_before_ms':before['p95_ms'],'p95_after_ms':after['p95_ms'],'cpu_before_ms':before['process_ms'],'cpu_after_ms':after['process_ms'],'memory_before':before['godot_static_bytes'],'memory_after':after['godot_static_bytes'],'draws_before':before['draw_calls'],'draws_after':after['draw_calls']})
  (out/'comparison.json').write_text(json.dumps({'baseline':args.baseline,'limitations':'Short llvmpipe diagnostic with no physical GPU or target hardware. Live AI and software-renderer variability; not a sustained FPS certification.','scenes':comparisons},indent=2)+'\n')
  for row in comparisons:print(json.dumps(row),flush=True)
 finally:subprocess.run(['git','worktree','remove','--force',str(base)],cwd=root,check=True)
