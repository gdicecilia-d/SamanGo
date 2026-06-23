import json

def cargar_usuario(uid, role_order):
    print(f"UID: {uid}")
    print(f"Buscando en orden: {role_order}")

cargar_usuario('test', ['operadores', 'estudiantes'])
