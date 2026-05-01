const https = require('http');
const data = JSON.stringify({
    code: 'var tree = Engine.get_main_loop() as SceneTree; var root = tree.root; var results = []; for (var i = 0; i < root.get_child_count(); i++) { var child = root.get_child(i); results.append(child.name + "(" + child.get_class() + ")"); } executeContext.output("root_children", JSON.stringify(results)); var wh = root.find_node("WarehousePanel", true, false); if (wh) { var gs = wh.find_child("EquippedGrid", true, false); executeContext.output("equipped_grid_found", str(gs != null)); if (gs) { executeContext.output("equipped_grid_size", str(gs.get_child_count())); } var ig = wh.find_child("InventoryGrid", true, false); executeContext.output("inventory_grid_found", str(ig != null)); if (ig) { executeContext.output("inventory_grid_size", str(ig.get_child_count())); } } else { executeContext.output("warehouse_panel", "NOT FOUND"); }',
    project_name: '类幸存者eve同人',
    type: 'editor'
});
const req = https.request({hostname:'localhost',port:5302,path:'/api/execute',method:'POST',headers:{'Authorization':'Bearer test-token-12345','Content-Type':'application/json','Content-Length':Buffer.byteLength(data)}}, res => { let b=''; res.on('data',c=>b+=c); res.on('end',()=>console.log(JSON.stringify(JSON.parse(b),null,2))); });
req.on('error',e=>console.log('ERR:',e.message));
req.write(data);
req.end();
