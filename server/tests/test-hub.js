const assert = require('assert');
const { parseYapeNotification } = require('../src/parser');

console.log('--- INICIANDO PRUEBAS DE PARSING DE NOTIFICACIONES YAPE ---');

// Caso 1: Notificación clásica "¡Te yapearon! S/ 15.00 de Juan Perez"
const case1 = parseYapeNotification('¡Te yapearon!', 'S/ 15.00 de Juan Perez', 'com.bcp.innovacxion.yapeapp');
console.log('Caso 1:', case1);
assert.strictEqual(case1.amount, 15);
assert.strictEqual(case1.sender, 'Juan Perez');
assert.strictEqual(case1.app, 'Yape');

// Caso 2: Notificación "Juan Carlos Quispe te envió S/ 45.50"
const case2 = parseYapeNotification('Yape', 'Juan Carlos Quispe te envió S/ 45.50', 'com.bcp.innovacxion.yapeapp');
console.log('Caso 2:', case2);
assert.strictEqual(case2.amount, 45.5);
assert.strictEqual(case2.sender, 'Juan Carlos Quispe');

// Caso 3: Notificación Plin "Recibiste S/ 30.00 de Maria Elena con Plin"
const case3 = parseYapeNotification('Plin Interbank', 'Recibiste S/ 30.00 de Maria Elena con Plin', 'pe.interbank.mobilebanking');
console.log('Caso 3:', case3);
assert.strictEqual(case3.amount, 30);
assert.strictEqual(case3.sender, 'Maria Elena');
assert.strictEqual(case3.app, 'Plin');

// Caso 4: Monto con comas "S/. 120,50 de Pedro Alva"
const case4 = parseYapeNotification('Notificación', 'Te yapearon S/. 120,50 de Pedro Alva', 'com.bcp.innovacxion.yapeapp');
console.log('Caso 4:', case4);
assert.strictEqual(case4.amount, 120.5);
assert.strictEqual(case4.sender, 'Pedro Alva');

console.log('✅ TODAS LAS PRUEBAS DE PARSING PASARON CORRECTAMENTE');
