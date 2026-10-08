/* Q2Ray Root regression tests for URI, subscription and Clash imports.
 * Synthetic fixtures only: never add real secrets or subscription tokens.
 */
const assert=require('node:assert/strict');
const nodes=require('../webroot/nodes.js');
const yaml=require('../webroot/vendor/js-yaml.min.js');
const uuid='12345678-1234-4234-8234-123456789abc';
const vless='vless://'+uuid+'@example.org:443?security=reality&sni=front.example.org&pbk=examplePubKey&sid=1234&fp=chrome&type=tcp#VN-VLESS';
const trojan='trojan://secret%24pass@trojan.example.org:443?security=tls&sni=t.example.org&type=ws&path=%2Fws&host=front.example.org#Test-Trojan';
const hy2='hysteria2://a%3Ab@h.example.org:8443?sni=hy.example.org&obfs=salamander&obfs-password=obfssecret&upmbps=50&downmbps=100#Hysteria2';
const hy2Short='hy2://hello@h.example.org:443?sni=h.example.org#HY2';
const ss='ss://'+Buffer.from('aes-128-gcm:ssPassword').toString('base64')+'@ss.example.org:8388#Shadowsocks';
const vmess='vmess://'+Buffer.from(JSON.stringify({v:'2',ps:'VMess',add:'vm.example.org',port:'443',id:uuid,aid:0,scy:'auto',net:'ws',type:'none',host:'vmhost.example.org',path:'/ws',tls:'tls',sni:'vm.example.org'})).toString('base64');
const tuic='tuic://'+uuid+':p4ss@tuic.example.org:443?sni=tuic.example.org&alpn=h3#TUIC';
const testList=[vless,trojan,hy2,hy2Short,ss,vmess,tuic];
for(const uri of testList){
 const item=nodes.uriToNode(uri);
 assert(item.name&&item.outbound.server&&item.outbound.server_port);
 const cfg=nodes.makeConfig(item);
 assert.equal(cfg.inbounds[0].type,'tproxy');
 assert.equal(cfg.inbounds[0].listen_port,9898);
 assert.equal(cfg.outbounds[0].tag,'proxy');
 assert.equal(cfg.route.final,'proxy');
 if(item.type==='hysteria2'){
   assert.equal(cfg.outbounds[0].tls.enabled,true);
   assert(item.outbound.password);
 }
}
const t=nodes.uriToNode(trojan);
assert.equal(t.outbound.password,'secret$pass');
assert.equal(t.outbound.transport.type,'ws');
assert.equal(t.outbound.transport.headers.Host,'front.example.org');
const h=nodes.uriToNode(hy2);
assert.equal(h.outbound.obfs.type,'salamander');
assert.equal(h.outbound.obfs.password,'obfssecret');
const plain=testList.join('\n');
const imported=nodes.parseSubscription(plain,yaml);
assert.equal(imported.nodes.length,7);
assert.equal(imported.errors.length,0);
const encoded=Buffer.from(plain,'utf8').toString('base64');
assert.equal(nodes.parseSubscription(encoded,yaml).nodes.length,7);
const clash=String.raw`
mixed-port: 7890
proxies:
  - name: "Clash VLESS"
    type: vless
    server: example.org
    port: 443
    uuid: 12345678-1234-4234-8234-123456789abc
    tls: true
    servername: front.example.org
    network: ws
    ws-opts:
      path: /vless
      headers:
        Host: custom.example.org
  - name: Clash HY2
    type: hysteria2
    server: hy2.example.org
    port: 443
    password: hello
    sni: hy.example.org
  - name: Clash SS
    type: ss
    server: ss.example.org
    port: 1443
    cipher: aes-128-gcm
    password: test-password
`;
const parsedClash=nodes.parseSubscription(clash,yaml);
assert.equal(parsedClash.nodes.length,3);
assert.equal(parsedClash.nodes[0].outbound.transport.type,'ws');
assert.equal(parsedClash.nodes[0].outbound.transport.headers.Host,'custom.example.org');
assert.equal(parsedClash.nodes[1].type,'hysteria2');
assert.equal(parsedClash.nodes[2].type,'shadowsocks');
const singboxSub={outbounds:[{tag:'Server A',type:'hysteria2',server:'h.example.org',server_port:443,password:'pass',tls:{enabled:true}}]};
assert.equal(nodes.parseSubscription(JSON.stringify(singboxSub),yaml).nodes.length,1);
assert.equal(nodes.parseSubscription([vless,vless].join('\n'),yaml).nodes.length,1);
assert.throws(()=>nodes.uriToNode('vless://abc@example.org:443'),/UUID/);
assert.throws(()=>nodes.uriToNode('ss://YQ==@example.org:443?plugin=v2ray-plugin'),/plugin/);
const fs=require('node:fs');
const path=require('node:path');
const dir='/tmp/q2r-test-configs';fs.mkdirSync(dir,{recursive:true});
for(const [index,uri] of testList.entries()){
 const name=nodes.uriToNode(uri);
 fs.writeFileSync(path.join(dir,'node-'+index+'.json'),JSON.stringify(nodes.makeConfig(name)));
}
for(const [index,item] of parsedClash.nodes.entries()){
 fs.writeFileSync(path.join(dir,'clash-'+index+'.json'),JSON.stringify(nodes.makeConfig(item)));
}
console.log('PASS: 7 URI types, plain/base64 subscriptions, Clash YAML, sing-box JSON, duplicate and error handling');
