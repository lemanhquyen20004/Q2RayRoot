/* Q2Ray Root — independent subscription/node parser.
 * Copyright (C) 2026 lemanhquyen20004
 * GPL-3.0-or-later.
 *
 * Accepts URI lines, base64 URI bundles, Clash YAML, a subset of
 * sing-box outbound JSON. Unsupported nodes are reported (not fabricated).
 * Nodes and credentials are never uploaded to this repository.
 */
(function(root,factory){
  const api=factory();
  if(typeof module==='object' && module.exports) module.exports=api;
  else root.Q2RNodes=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';

const supported=new Set(['vless','trojan','vmess','ss','hysteria2','hy2','hysteria','tuic']);
const sbTypes=new Set(['vless','trojan','vmess','shadowsocks','hysteria2','hysteria','tuic']);
function fail(message){throw new Error(message);}
function utf8b64(s){
  let b=String(s||'').replace(/\s/g,'').replace(/-/g,'+').replace(/_/g,'/');
  if(!/^[A-Za-z0-9+/]*={0,2}$/.test(b)||b.length<4)fail('Invalid base64');
  b=b.padEnd(Math.ceil(b.length/4)*4,'=');
  const decoded=(typeof atob==='function')?atob(b):Buffer.from(b,'base64').toString('binary');
  if(typeof TextDecoder==='function'){
    const bytes=Uint8Array.from(decoded, c=>c.charCodeAt(0));
    return new TextDecoder('utf-8',{fatal:true}).decode(bytes);
  }
  return decodeURIComponent(Array.from(decoded,c=>'%'+c.charCodeAt(0).toString(16).padStart(2,'0')).join(''));
}
function intPort(v){
 const n=Number(v);if(!Number.isInteger(n)||n<1||n>65535)fail('Invalid port');
 return n;
}
function intOrZero(v){const n=Number(v);return Number.isFinite(n)&&n>0?Math.trunc(n):0;}
function text(v){return v==null?'':String(v);}
function bool(v){return v===true||v===1||v==='1'||v==='true'||v==='yes';}
function label(v,fallback){
 try{return decodeURIComponent(text(v).replace(/^#/,'')).trim().slice(0,120)||fallback;}catch(e){return text(v).slice(0,120)||fallback;}
}
function tlsFor(server,opt,required){
 opt=opt||{};
 const sec=text(opt.security||opt.secure||'').toLowerCase();
 const active=required||bool(opt.tls)||sec==='tls'||sec==='reality';
 if(!active)return undefined;
 const tls={enabled:true,server_name:text(opt.sni||opt.servername||opt.peer||server)};
 if(bool(opt.insecure)||bool(opt['skip-cert-verify'])||bool(opt.allowInsecure))tls.insecure=true;
 const fingerprint=text(opt.fp||opt['client-fingerprint']||'');
 if(fingerprint && fingerprint!=='none')tls.utls={enabled:true,fingerprint};
 const publicKey=text(opt.pbk||opt['public-key']||(opt['reality-opts']||{})['public-key']);
 if(sec==='reality'||publicKey){
   if(!publicKey)fail('REALITY public key missing');
   tls.reality={enabled:true,public_key:publicKey,short_id:text(opt.sid||opt['short-id']||(opt['reality-opts']||{})['short-id'])};
 }
 const alpn=text(opt.alpn||'');
 if(alpn)tls.alpn=alpn.split(',').map(x=>x.trim()).filter(Boolean);
 else if(Array.isArray(opt.alpn))tls.alpn=opt.alpn;
 return tls;
}
function transportFor(o){
 o=o||{};
 const name=text(o.type||o.network||o.net||'tcp').toLowerCase();
 if(name==='tcp'||name==='none')return undefined;
 if(name==='ws'||name==='websocket'){
   const opts=o['ws-opts']||o;
   const hdr=opts.headers||{};
   const host=text(o.host||o['ws-host']||hdr.Host||hdr.host);
   const t={type:'ws',path:text(opts.path||o.path||'/')};
   if(host)t.headers={Host:host};
   return t;
 }
 if(name==='grpc'){
   const opts=o['grpc-opts']||o;
   return {type:'grpc',service_name:text(opts['grpc-service-name']||opts.serviceName||o.serviceName||'')};
 }
 if(name==='httpupgrade'){
   return {type:'httpupgrade',host:text(o.host||''),path:text(o.path||'/')};
 }
 if(name==='http'||name==='h2'){
   const opts=o['h2-opts']||o;
   const h=opts.host||o.host||[];
   return {type:'http',host:Array.isArray(h)?h:[text(h)],path:text(opts.path||o.path||'/')};
 }
 // XHTTP is not supported by the sing-box 1.14 transport schema.
 fail('Transport '+name+' is not supported by sing-box 1.14');
}
function hostAndPort(u){
 const server=u.hostname.replace(/^\[|\]$/g,'');
 if(!server||server.length>253)fail('Invalid server');
 return {server,server_port:intPort(u.port)};
}
function uriToNode(source){
 let uri=text(source).trim();
 if(!/^[a-z][a-z0-9+.-]*:\/\//i.test(uri))fail('Invalid node URI');
 const kind=uri.split(':',1)[0].toLowerCase();
 if(!supported.has(kind))fail('Unsupported protocol: '+kind);
 if(kind==='vmess' && !uri.slice(8).includes('@')){
   const json=JSON.parse(utf8b64(uri.slice(8).split('#')[0]));
   return clashToNode({type:'vmess',name:text(json.ps)||'VMess',server:json.add,port:json.port,
     uuid:json.id,alterId:json.aid,cipher:json.scy||'auto',
     tls:json.tls==='tls',servername:json.sni||json.servername,
     network:json.net||'tcp', 'ws-opts':{path:json.path||'/',headers:{Host:json.host||''}},
     'grpc-opts':{'grpc-service-name':json.path||''},alpn:json.alpn},uri);
 }
 if(kind==='ss'){
   const body=uri.substring(5);
   const hashAt=body.indexOf('#');
   let credentials=hashAt>=0?body.slice(0,hashAt):body;
   const nm=hashAt>=0?label(body.slice(hashAt+1),'Shadowsocks'):'Shadowsocks';
   const queryAt=credentials.indexOf('?');
   if(queryAt>=0){
     const opts=new URLSearchParams(credentials.slice(queryAt+1));
     if(opts.has('plugin'))fail('Shadowsocks SIP003 plugin not supported');
     credentials=credentials.slice(0,queryAt);
   }
   let userinfo,server,port;
   if(credentials.includes('@')){
     const idx=credentials.lastIndexOf('@');
     userinfo=credentials.slice(0,idx);
     if(!userinfo.includes(':'))userinfo=utf8b64(userinfo);
     const a=new URL('https://'+credentials.slice(idx+1));
     server=a.hostname;port=intPort(a.port);
   }else{
     const dec=utf8b64(credentials);
     const idx=dec.lastIndexOf('@');
     if(idx<0)fail('Invalid Shadowsocks URI');
     userinfo=dec.slice(0,idx);
     const a=new URL('https://'+dec.slice(idx+1));
     server=a.hostname;port=intPort(a.port);
   }
   userinfo=decodeURIComponent(userinfo);
   const colon=userinfo.indexOf(':');if(colon<0)fail('Shadowsocks method/password missing');
   return finish({type:'shadowsocks',server,server_port:port,method:userinfo.slice(0,colon),password:userinfo.slice(colon+1)},nm,uri);
 }
 const u=new URL(uri.replace(/^hy2:/i,'hysteria2:'));
 const hp=hostAndPort(u),q=u.searchParams;
 const p=Object.fromEntries(q.entries());
 let nm=label(u.hash,'');
 let out={...hp,type:kind==='hy2'?'hysteria2':kind};
 if(!nm)nm=(kind.toUpperCase()+' '+hp.server);
 if(kind==='vless'){
   const uuid=decodeURIComponent(u.username);
   if(!/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(uuid))fail('Invalid VLESS UUID');
   out.uuid=uuid;
   const sec=text(q.get('security')||'tls');
   if(sec!=='tls'&&sec!=='reality'&&sec!=='none')fail('Unsupported VLESS security');
   if(sec==='none')fail('Plaintext VLESS is not supported by this importer');
   out.tls=tlsFor(hp.server,{...p,security:sec},true);
   const flow=q.get('flow');if(flow)out.flow=flow;
   out.transport=transportFor({...p,type:q.get('type')||'tcp'});
 } else if(kind==='trojan'){
   out.password=decodeURIComponent(u.username);
   if(!out.password)fail('Trojan password missing');
   out.tls=tlsFor(hp.server,p,true);
   out.transport=transportFor({...p,type:q.get('type')||'tcp'});
 } else if(kind==='vmess'){
   out.uuid=decodeURIComponent(u.username);
   if(!out.uuid)fail('VMess UUID missing');
   out.security=text(p.security||'auto');
   out.alter_id=intOrZero(p.aid);
   out.tls=tlsFor(hp.server,p,false);
   out.transport=transportFor({...p,type:p.type||'tcp'});
 } else if(kind==='hysteria2'||kind==='hy2'){
   out.password=decodeURIComponent(u.username)||text(p.auth);
   if(!out.password)fail('Hysteria2 password missing');
   out.tls=tlsFor(hp.server,p,true);
   const up=intOrZero(p.upmbps||p.up),down=intOrZero(p.downmbps||p.down);
   if(up)out.up_mbps=up;if(down)out.down_mbps=down;
   const obfs=p.obfs||p['obfs-type'],pw=p['obfs-password']||p.obfsPassword;
   if(obfs){if(!pw)fail('Hysteria2 obfs password missing');out.obfs={type:obfs,password:pw};}
 } else if(kind==='hysteria'){
   out.auth_str=text(p.auth||p.auth_str||decodeURIComponent(u.username));
   if(!out.auth_str)fail('Hysteria password missing');
   out.up_mbps=intOrZero(p.upmbps||p.up);
   out.down_mbps=intOrZero(p.downmbps||p.down);
   if(!out.up_mbps||!out.down_mbps)fail('Hysteria up/down Mbps required');
   if(p.obfs)out.obfs=p.obfs;
   out.tls=tlsFor(hp.server,p,true);
 } else if(kind==='tuic'){
   out.uuid=decodeURIComponent(u.username);
   out.password=decodeURIComponent(u.password);
   if(!out.uuid||!out.password)fail('TUIC UUID/password missing');
   out.tls=tlsFor(hp.server,p,true);
   if(!out.tls.alpn)out.tls.alpn=['h3'];
   if(p.congestion_control||p.congestion)out.congestion_control=p.congestion_control||p.congestion;
 }
 if(out.transport===undefined)delete out.transport;
 return finish(out,nm,uri);
}
function finish(out,name,raw){
 if(!sbTypes.has(out.type))fail('Unknown sing-box type '+out.type);
 if(!out.server||!Number.isInteger(Number(out.server_port)))fail('Invalid address/port');
 const o=JSON.parse(JSON.stringify(out));
 o.server_port=intPort(o.server_port);
 const type=o.type;
 delete o.tag;
 const id=hash(type+'|'+o.server+'|'+o.server_port+'|'+text(o.uuid||o.password||o.auth_str||o.method));
 return {id,name:label(name,type+' '+o.server),type,engine:'sing-box',outbound:o,source:raw?'uri':'subscription'};
}
function hash(s){
 let h=2166136261;
 for(const c of String(s)){h^=c.charCodeAt(0);h=Math.imul(h,16777619);}
 return (h>>>0).toString(16).padStart(8,'0');
}
function clashToNode(p,raw){
 if(!p||typeof p!=='object')fail('Invalid Clash proxy item');
 let type=text(p.type).toLowerCase();
 if(type==='ss')type='shadowsocks';
 if(type==='hy2')type='hysteria2';
 if(!sbTypes.has(type))fail('Unsupported Clash type '+type);
 let out={type,server:text(p.server||p.address),server_port:intPort(p.port||p.server_port)};
 if(type==='vless'){
   out.uuid=text(p.uuid);
   if(!out.uuid)fail('VLESS UUID missing');
   if(p.flow)out.flow=text(p.flow);
   out.tls=tlsFor(out.server,{...p,security:p['reality-opts']?'reality':p.security||'tls'},true);
   out.transport=transportFor({...p,type:p.network||'tcp'});
 }else if(type==='trojan'){
   out.password=text(p.password);
   if(!out.password)fail('Trojan password missing');
   out.tls=tlsFor(out.server,p,true);
   out.transport=transportFor({...p,type:p.network||'tcp'});
 }else if(type==='vmess'){
   out.uuid=text(p.uuid);
   if(!out.uuid)fail('VMess UUID missing');
   out.security=text(p.cipher||'auto');
   out.alter_id=intOrZero(p.alterId||p.alter_id);
   out.tls=tlsFor(out.server,p,false);
   out.transport=transportFor({...p,type:p.network||'tcp'});
 }else if(type==='shadowsocks'){
   if(p.plugin)fail('Shadowsocks plugins are not supported');
   out.method=text(p.cipher||p.method);out.password=text(p.password);
   if(!out.method||!out.password)fail('Shadowsocks method/password missing');
 }else if(type==='hysteria2'){
   out.password=text(p.password||p.auth);
   if(!out.password)fail('Hysteria2 password missing');
   out.tls=tlsFor(out.server,p,true);
   out.up_mbps=intOrZero(p.up||p.up_mbps);
   out.down_mbps=intOrZero(p.down||p.down_mbps);
   if(!out.up_mbps)delete out.up_mbps;if(!out.down_mbps)delete out.down_mbps;
   if(p.obfs){out.obfs={type:text(p.obfs),password:text(p['obfs-password']||p.obfs_password)};}
 }else if(type==='hysteria'){
   out.auth_str=text(p['auth-str']||p.auth||p.password);
   out.up_mbps=intOrZero(p.up||p.up_mbps);
   out.down_mbps=intOrZero(p.down||p.down_mbps);
   out.tls=tlsFor(out.server,p,true);
   if(!out.auth_str||!out.up_mbps||!out.down_mbps)fail('Hysteria auth/up/down required');
 }else if(type==='tuic'){
   out.uuid=text(p.uuid);out.password=text(p.password);
   out.tls=tlsFor(out.server,p,true);
   if(!out.uuid||!out.password)fail('TUIC UUID/password missing');
   if(p['congestion-controller'])out.congestion_control=text(p['congestion-controller']);
 }
 if(out.transport===undefined)delete out.transport;
 return finish(out,text(p.name||p.tag||type+' '+out.server),raw);
}
function safeJSONParse(src){
 try{return JSON.parse(src);}catch(e){return null;}
}
function extractObject(data,errors){
 const arr=[];
 if(Array.isArray(data)){
   for(const row of data){
     try{
       if(typeof row==='string')arr.push(uriToNode(row));
       else arr.push(clashToNode(row));
     }catch(e){errors.push(e.message);}
   }
   return arr;
 }
 if(!data||typeof data!=='object')return arr;
 if(Array.isArray(data.proxies))return extractObject(data.proxies,errors);
 if(Array.isArray(data.nodes))return extractObject(data.nodes,errors);
 if(Array.isArray(data.outbounds)){
   for(const item of data.outbounds){
     if(!sbTypes.has(text(item.type)))continue;
     try{arr.push(finish(item,item.tag||item.type));}
     catch(e){errors.push(e.message);}
   }
   return arr;
 }
 return arr;
}
function parseSubscription(raw,yamlLib){
 let input=text(raw).replace(/^\uFEFF/,'').trim();
 const errors=[],nodes=[];
 if(!input)fail('Subscription is empty');
 if(input.length>1500000)fail('Subscription too large');
 // Handle Clash YAML, sing-box JSON or JSON node arrays first.
 let object=safeJSONParse(input);
 if(!object&&/^\s*(proxies|proxy-providers|mixed-port|port)\s*:/m.test(input)){
   const parser=yamlLib||((typeof globalThis!=='undefined'&&globalThis.jsyaml)?globalThis.jsyaml:null);
   if(!parser||typeof parser.load!=='function')fail('Clash YAML parser unavailable');
   try{object=parser.load(input,{json:true});}catch(e){fail('Invalid Clash YAML: '+e.message);}
 }
 if(object){
   nodes.push(...extractObject(object,errors));
 }else{
   if(!/^(vless|trojan|vmess|ss|hy2|hysteria2|hysteria|tuic):\/\//im.test(input)){
     try{
       const decoded=utf8b64(input);
       if(decoded.includes('://'))input=decoded;
     }catch(e){}
   }
   const lines=input.split(/\r?\n/);
   for(const line of lines){
     const s=line.trim();
     if(!s||s.startsWith('#')||s.startsWith('//'))continue;
     if(!/^[a-z][a-z0-9+.-]*:\/\//i.test(s))continue;
     try{nodes.push(uriToNode(s));}catch(e){errors.push(e.message);}
   }
 }
 const unique=[],seen=new Set();
 for(const n of nodes)if(!seen.has(n.id)){seen.add(n.id);unique.push(n);}
 if(unique.length>500)fail('Subscription contains too many nodes (max 500)');
 return {nodes:unique,errors};
}
function makeConfig(node){
 if(!node||node.engine!=='sing-box'||!node.outbound)fail('Node selection missing');
 const selected=JSON.parse(JSON.stringify(node.outbound));
 if(!sbTypes.has(selected.type))fail('Unsupported node protocol');
 selected.tag='proxy';
 return {
  log:{level:'warn'},
  inbounds:[{type:'tproxy',tag:'tproxy-in',listen:'0.0.0.0',listen_port:9898}],
  outbounds:[selected,{type:'direct',tag:'direct'},{type:'block',tag:'block'}],
  route:{final:'proxy',auto_detect_interface:true}
 };
}
return {parseSubscription,uriToNode,clashToNode,makeConfig,utf8b64};
});
