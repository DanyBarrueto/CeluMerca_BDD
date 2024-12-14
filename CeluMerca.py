from datetime import datetime
from pymongo import MongoClient
import pymysql
import mysql.connector
from mysql.connector import Error
import os
import math

# Conexión noSQL
try:
    client = MongoClient("mongodb+srv://root:12345@clustergratis.x4rmc.mongodb.net/")
    db = client["CeluMerca"]
    comments_collection = db["Comentarios"]
    print("Conexión exitosa a MongoDB")
except Exception as e:
    print("Error al conectar a MongoDB:", e)

# Conexión MySQL
try:
    mysql_conn = pymysql.connect(
        host="localhost",
        user="root",
        password="",
        database="merca"
    )
    print("Conexión exitosa a MySQL")
except pymysql.MySQLError as e:
    print("Error al conectar a MySQL:", e)

def limpiar_consola():
    os.system('cls' if os.name == 'nt' else 'clear')

# Configuración de la conexión a la base de datos
def conectar():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="merca"
    )

# Función para calcular la distancia usando la fórmula de Haversine
def calcular_distancia(lat1, lon1, lat2, lon2):
    # Radio de la Tierra en kilómetros
    R = 6371.0
    # Convertir grados a radianes
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# Función para ver las sucursales más cercanas
def sucursales_cercanas(usuario):
    try:
        conexion = conectar()
        cursor = conexion.cursor(dictionary=True)

        # Obtener la ubicación del cliente actual
        lat_cliente = usuario["latitud"]
        lon_cliente = usuario["longitud"]

        # Obtener las sucursales desde la base de datos
        consulta = "SELECT id_sucursal, nombre, latitud, longitud FROM sucursales"
        cursor.execute(consulta)
        sucursales = cursor.fetchall()

        # Calcular la distancia a cada sucursal
        for sucursal in sucursales:
            distancia = calcular_distancia(lat_cliente, lon_cliente, sucursal["latitud"], sucursal["longitud"])
            sucursal["distancia"] = distancia

        # Ordenar las sucursales por distancia
        sucursales_ordenadas = sorted(sucursales, key=lambda x: x["distancia"])

        # Mostrar las sucursales ordenadas
        print("\n=== Sucursales más cercanas ===")
        for sucursal in sucursales_ordenadas:
            print(f"Sucursal: {sucursal['nombre']} (ID: {sucursal['id_sucursal']}) - Distancia: {sucursal['distancia']:.2f} km")

        # Opción para volver al menú principal
        input("\nPresione Enter para volver al menú principal.")

    except Error as e:
        print("Error al obtener sucursales:", e)

    finally:
        if conexion.is_connected():
            cursor.close()
            conexion.close()

# Función para registrar un nuevo usuario
def registrar_usuario():
    try:
        conexion = conectar()
        cursor = conexion.cursor()

        nombre = input("Ingrese su nombre: ")
        correo = input("Ingrese su correo electrónico: ")
        direccion = input("Ingrese su dirección: ")
        latitud = float(input("Ingrese la latitud: "))
        longitud = float(input("Ingrese la longitud: "))
        contraseña = input("Ingrese su contraseña: ")

        consulta = """
        INSERT INTO clientes (nombre, correo_electronico, direccion, latitud, longitud, contraseña)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        valores = (nombre, correo, direccion, latitud, longitud, contraseña)

        cursor.execute(consulta, valores)
        conexion.commit()
        print("Usuario registrado con éxito.")

    except Error as e:
        print("Error al registrar el usuario:", e)

    finally:
        if conexion.is_connected():
            cursor.close()
            conexion.close()

# Función para iniciar sesión
def iniciar_sesion():
    try:
        conexion = conectar()
        cursor = conexion.cursor(dictionary=True)

        correo = input("Ingrese su correo electrónico: ")
        contraseña = input("Ingrese su contraseña: ")

        consulta = """
        SELECT * FROM clientes WHERE correo_electronico = %s AND contraseña = %s
        """
        valores = (correo, contraseña)

        cursor.execute(consulta, valores)
        usuario = cursor.fetchone()

        if usuario:
            print(f"Bienvenido, {usuario['nombre']}!")
            return usuario
        else:
            print("Correo o contraseña incorrectos.")
            return None

    except Error as e:
        print("Error al iniciar sesión:", e)

    finally:
        if conexion.is_connected():
            cursor.close()
            conexion.close()

# Función para listar productos
def listar_productos():
    try:
        conexion = conectar()
        cursor = conexion.cursor(dictionary=True)

        consulta = "SELECT * FROM productos"
        cursor.execute(consulta)
        productos = cursor.fetchall()

        print("Productos disponibles:")
        for producto in productos:
            print(f"{producto['id_producto']}. {producto['nombre']} - ${producto['precio']} (Stock: {producto['stock']})")

        return productos

    except Error as e:
        print("Error al listar productos:", e)
        return []

    finally:
        if conexion.is_connected():
            cursor.close()
            conexion.close()

# Función para realizar una compra
def realizar_compra(usuario):
    try:
        conexion = conectar()
        cursor = conexion.cursor()

        carrito = []
        total = 0

        while True:
            productos = listar_productos()
            if not productos:
                return

            id_producto = int(input("Ingrese el ID del producto que desea comprar: "))
            cantidad = int(input("Ingrese la cantidad que desea comprar: "))

            consulta = "SELECT nombre, precio, stock FROM productos WHERE id_producto = %s"
            cursor.execute(consulta, (id_producto,))
            producto = cursor.fetchone()

            if producto and cantidad <= producto[2]:  # Validar stock
                carrito.append((id_producto, producto[0], cantidad, producto[1] * cantidad))
                total += producto[1] * cantidad
                print(f"Producto {producto[0]} agregado al carrito.")
            else:
                print("Cantidad no disponible en el stock.")

            agregar_mas = input("¿Desea agregar otro producto? (s/n): ").strip().lower()
            if agregar_mas != 's':
                break

        # Mostrar resumen del carrito
        limpiar_consola()
        print("\nResumen de su compra:")
        for item in carrito:
            print(f"Producto: {item[1]}, Cantidad: {item[2]}, Subtotal: ${item[3]:.2f}")
        print(f"Total a pagar: ${total:.2f}")

        # Confirmar compra
        confirmar = input("¿Desea confirmar su compra? (s/n): ").strip().lower()
        if confirmar == 's':
            limpiar_consola()
            for item in carrito:
                # Llamar al procedimiento almacenado `registro_compra`
                consulta_compra = "CALL registro_compra(%s, %s, %s)"
                valores = (usuario['id_cliente'], item[0], item[2])
                cursor.execute(consulta_compra, valores)

            conexion.commit()
            print("Compra realizada con éxito.")
        else:
            print("Compra cancelada. Regresando al menú.")

    except Error as e:
        if e.errno == 1644:  # Error personalizado del disparador
            print("Error:", e.msg)
        else:
            print("Error al realizar la compra:", e)

    finally:
        if conexion.is_connected():
            cursor.close()
            conexion.close()

#Gestionar comentarios
def gestionar_comentarios(usuario):
    while True:
        print("\n=== Comentarios de Productos ===")
        try:
            conexion = conectar()
            cursor = conexion.cursor(dictionary=True)
            
            # Listar productos
            productos = {}
            cursor.execute("SELECT id_producto, nombre FROM productos")
            for prod in cursor.fetchall():
                productos[prod['id_producto']] = prod['nombre']
            
            # Obtener nombres de usuarios desde MySQL
            usuarios = {}
            cursor.execute("SELECT id_cliente, nombre FROM clientes")
            for usr in cursor.fetchall():
                usuarios[usr['id_cliente']] = usr['nombre']
            
            # Mostrar comentarios desde MongoDB
            comentarios = list(comments_collection.find())
            if comentarios:
                print("\nComentarios registrados:\n")
                for comentario in comentarios:
                    nombre_producto = productos.get(comentario['id_producto'], "Producto desconocido")
                    nombre_usuario = comentario.get('usuario', "Usuario desconocido")
                    print(f"Producto: {nombre_producto} | Usuario: {nombre_usuario} | "
                          f"Calificación: {comentario['calificacion']} | Comentario: {comentario['comentario']}")
                    print("-" * 50)
            else:
                print("No hay comentarios registrados aún.")
            
            # Opciones del menú
            print("\nOpciones:")
            print("1. Agregar comentario")
            print("2. Modificar comentario propio")
            print("3. Eliminar comentario propio")
            print("4. Volver al menú principal")
            opcion = input("Seleccione una opción: ").strip()
            
            if opcion == "1":
                limpiar_consola()
                # Agregar un nuevo comentario
                print("\nProductos disponibles:")
                for id_prod, nombre_prod in productos.items():
                    print(f"{id_prod}. {nombre_prod}")
                
                id_producto = int(input("Ingrese el ID del producto a comentar: "))
                if id_producto not in productos:
                    print("El ID del producto no es válido.")
                    continue
                calificacion = int(input("Ingrese su calificación (1-5): "))
                if calificacion < 1 or calificacion > 5:
                    print("La calificación debe estar entre 1 y 5.")
                    continue
                comentario = input("Ingrese su comentario: ").strip()
                
                nuevo_comentario = {
                    'id_comentario': comments_collection.count_documents({}) + 1,
                    'id_producto': id_producto,
                    'usuario': usuarios.get(usuario['id_cliente'], "Usuario desconocido"),
                    'calificacion': calificacion,
                    'comentario': comentario,
                    'hora': datetime.now()
                }
                comments_collection.insert_one(nuevo_comentario)
                print("Comentario agregado exitosamente.")
            
            elif opcion == "2":
                limpiar_consola()
                # Modificar un comentario propio
                comentarios_usuario = list(
                    comments_collection.find({'usuario': usuarios.get(usuario['id_cliente'], "Usuario desconocido")})
                )
                if not comentarios_usuario:
                    print("No tiene comentarios propios para modificar.")
                    continue
                
                print("\nSus comentarios:")
                for comentario in comentarios_usuario:
                    nombre_producto = productos.get(comentario['id_producto'], "Producto desconocido")
                    print(f"ID: {comentario['id_comentario']} | Producto: {nombre_producto} | "
                          f"Calificación: {comentario['calificacion']} | Comentario: {comentario['comentario']}")
                    print("-" * 50)
                
                id_comentario = int(input("Ingrese el ID del comentario que desea modificar: "))
                comentario = comments_collection.find_one(
                    {'id_comentario': id_comentario, 'usuario': usuarios.get(usuario['id_cliente'], "Usuario desconocido")}
                )
                if not comentario:
                    print("El comentario no existe o no es suyo.")
                    continue
                
                nuevo_comentario = input("Ingrese el nuevo comentario: ").strip()
                nueva_calificacion = int(input("Ingrese la nueva calificación (1-5): "))
                if nueva_calificacion < 1 or nueva_calificacion > 5:
                    print("La calificación debe estar entre 1 y 5.")
                    continue
                
                comments_collection.update_one(
                    {'id_comentario': id_comentario},
                    {'$set': {'comentario': nuevo_comentario, 'calificacion': nueva_calificacion, 'hora': datetime.now()}}
                )
                print("Comentario modificado exitosamente.")
            
            elif opcion == "3":
                limpiar_consola()
                # Eliminar un comentario propio
                comentarios_usuario = list(
                    comments_collection.find({'usuario': usuarios.get(usuario['id_cliente'], "Usuario desconocido")})
                )
                if not comentarios_usuario:
                    print("No tiene comentarios propios para eliminar.")
                    continue
                
                print("\nSus comentarios:")
                for comentario in comentarios_usuario:
                    nombre_producto = productos.get(comentario['id_producto'], "Producto desconocido")
                    print(f"ID: {comentario['id_comentario']} | Producto: {nombre_producto} | "
                          f"Calificación: {comentario['calificacion']} | Comentario: {comentario['comentario']}")
                    print("-" * 50)
                
                id_comentario = int(input("Ingrese el ID del comentario que desea eliminar: "))
                comentario = comments_collection.find_one(
                    {'id_comentario': id_comentario, 'usuario': usuarios.get(usuario['id_cliente'], "Usuario desconocido")}
                )
                if not comentario:
                    print("El comentario no existe o no es suyo.")
                    continue
                
                comments_collection.delete_one({'id_comentario': id_comentario})
                print("Comentario eliminado exitosamente.")
            
            elif opcion == "4":
                # Volver al menú principal
                print("Regresando al menú principal.")
                break
            
            else:
                print("Opción no válida. Intente nuevamente.")
        
        except Exception as e:
            print("Error al gestionar comentarios:", e)
        
        finally:
            if conexion.is_connected():
                cursor.close()
                conexion.close()

# Menú principal
def menu_principal():
    while True:
        print("\n=== Menú Principal ===")
        print("1. Registrar usuario")
        print("2. Iniciar sesión")
        print("3. Salir")

        opcion = input("Seleccione una opción: ")

        if opcion == "1":
            limpiar_consola()
            registrar_usuario()
        elif opcion == "2":
            limpiar_consola()
            usuario = iniciar_sesion()
            if usuario:
                limpiar_consola()
                menu_usuario(usuario)
        elif opcion == "3":
            print("Saliendo del programa. ¡Hasta luego!")
            break
        else:
            print("Opción no válida. Intente nuevamente.")

# Menú para usuarios autenticados
def menu_usuario(usuario):
    while True:
        print("\n=== Menú Usuario ===")
        print("1. Comprar productos")
        print("2. Comentar productos")
        print("3. Ver sucursales cercanas")
        print("4. Cerrar sesión")

        opcion = input("Seleccione una opción: ")

        if opcion == "1":
            limpiar_consola()
            realizar_compra(usuario)
        elif opcion == "2":
            limpiar_consola()
            gestionar_comentarios(usuario)
        elif opcion == "3":
            limpiar_consola()
            sucursales_cercanas(usuario)
        elif opcion == "4":
            print("Cerrando sesión. Regresando al menú principal.")
            break
        else:
            print("Opción no válida. Intente nuevamente.")

# Inicio del programa
if __name__ == "__main__":
    menu_principal()

# Cerrar la conexión MySQL si está activa
try:
    if mysql_conn.open:
        mysql_conn.close()
        print("Conexión a MySQL cerrada correctamente")
except NameError:
    print("No se pudo establecer una conexión para cerrar.")
