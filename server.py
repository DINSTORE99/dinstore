#!/usr/bin/env python3
import json, os, subprocess, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
CFG=Path('/etc/dinstore'); USERS=CFG/'users.json'; BACKUPS=Path('/var/backups/dinstore')
API_KEY=os.getenv('API_KEY','').strip(); HOST=os.getenv('API_HOST','127.0.0.1'); PORT=int(os.getenv('API_PORT','8080'))
def json_out(handler, code, obj):
    data=json.dumps(obj, ensure_ascii=False).encode(); handler.send_response(code); handler.send_header('Content-Type','application/json'); handler.send_header('Content-Length',str(len(data))); handler.end_headers(); handler.wfile.write(data)
def auth(h):
    if not API_KEY: return False
    return h.headers.get('X-API-Key','') == API_KEY
class H(BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_GET(self):
        if self.path == '/health': return json_out(self,200,{'ok':True})
        if not auth(self): return json_out(self,401,{'ok':False,'error':'unauthorized'})
        if self.path == '/api/v1/status':
            sv={};
            for s in ['nginx','xray','dinstore-api','openvpn-server@server']:
                p=subprocess.run(['systemctl','is-active',s],capture_output=True,text=True); sv[s]=p.stdout.strip() or 'unknown'
            return json_out(self,200,{'ok':True,'time':int(time.time()),'services':sv})
        if self.path == '/api/v1/users':
            try: return json_out(self,200,json.loads(USERS.read_text()))
            except Exception: return json_out(self,200,{'users':[]})
        if self.path == '/api/v1/backups':
            return json_out(self,200,{'backups':[{'name':p.name,'size':p.stat().st_size} for p in sorted(BACKUPS.glob('dinstore-*.tar.gz'))]})
        if self.path == '/api/v1/backup/config':
            c={};
            for line in (CFG/'config.env').read_text().splitlines():
                if line.startswith(('BACKUP_ENABLED=','BACKUP_RETENTION=','BACKUP_TIME=')): k,v=line.split('=',1); c[k]=v
            return json_out(self,200,{'ok':True,**c})
        return json_out(self,404,{'ok':False,'error':'not_found'})
    def do_POST(self):
        if not auth(self): return json_out(self,401,{'ok':False,'error':'unauthorized'})
        n=int(self.headers.get('Content-Length','0')); raw=self.rfile.read(n) if n else b'{}'
        try: body=json.loads(raw or b'{}')
        except Exception: return json_out(self,400,{'ok':False,'error':'invalid_json'})
        if self.path == '/api/v1/backup':
            p=subprocess.run(['/opt/dinstore/bin/backup.sh','api'],capture_output=True,text=True); return json_out(self,200 if p.returncode==0 else 500,{'ok':p.returncode==0,'file':p.stdout.strip(),'error':p.stderr.strip()})
        if self.path == '/api/v1/backup/config':
            cfg=CFG/'config.env'; lines=cfg.read_text().splitlines(); changes=body if isinstance(body,dict) else {}
            allowed={'BACKUP_ENABLED','BACKUP_RETENTION','BACKUP_TIME','SC_ORDER'}
            out=[]
            for line in lines:
                if '=' in line and line.split('=',1)[0] in allowed and line.split('=',1)[0] in changes: line=line.split('=',1)[0]+'='+str(changes[line.split('=',1)[0]])
                out.append(line)
            cfg.write_text('\n'.join(out)+'\n'); subprocess.run(['systemctl','daemon-reload']); subprocess.run(['systemctl','restart','dinstore-backup.timer']); return json_out(self,200,{'ok':True,'note':'timer menggunakan nilai BACKUP_TIME baru'})
        if self.path == '/api/v1/users':
            if not isinstance(body,dict) or not body.get('username'): return json_out(self,400,{'ok':False,'error':'username_required'})
            u=str(body['username']); days=int(body.get('days',30));
            p=subprocess.run(['/opt/dinstore/bin/user.sh','add',u,str(days)],capture_output=True,text=True)
            if p.returncode: return json_out(self,409,{'ok':False,'error':p.stderr.strip() or p.stdout.strip()})
            lines=dict(x.split('=',1) for x in p.stdout.splitlines() if '=' in x)
            return json_out(self,201,{'ok':True,'user':lines})
        if self.path == '/api/v1/users/delete':
            u=str(body.get('username','')); 
            if not u: return json_out(self,400,{'ok':False,'error':'username_required'})
            p=subprocess.run(['/opt/dinstore/bin/user.sh','del',u],capture_output=True,text=True); return json_out(self,200 if p.returncode==0 else 500,{'ok':p.returncode==0})
        return json_out(self,404,{'ok':False,'error':'not_found'})
if __name__=='__main__': ThreadingHTTPServer((HOST,PORT),H).serve_forever()
