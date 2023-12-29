# -*- coding: utf-8 -*-
"""
Created on Mon Oct 30 06:34:46 2023

@author: marie
"""

""""import http.server
 
PORT = 8888
server_address = ("", PORT)

server = http.server.HTTPServer
handler = http.server.CGIHTTPRequestHandler
handler.cgi_directories = ["/cgi-bin"]
print("Serveur actif sur le port :", PORT)

httpd = server(server_address, handler)
httpd.serve_forever()

"""
from flask import Flask, render_template, request, redirect, url_for, jsonify

from http.server import CGIHTTPRequestHandler, HTTPServer
import subprocess
import pymysql
import hashlib
# Paramètres de connexion à la base de données MySQL
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'root',
    'db': 'stationblanche',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

app = Flask(__name__)

class MyCGIHandler(CGIHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/trigger-scan':
            # Exécuter le script shell pour numériser la clé USB
            scan_script_path = '/home/marieme/Station-Blanche-USB/station-blanche/scan_and_log.sh'
            try:
                subprocess.run(['bash', scan_script_path], check=True)
                
                # Maintenant, exécutez également le script Python pour vérifier la clé USB
                subprocess.run(['python3', '/home/marieme/Station-Blanche-USB/web/extraction_hash.py'], check=True)
                
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write('La numérisation a été déclenchée avec succès.'.encode('utf-8'))
            except subprocess.CalledProcessError as e:
                self.send_response(500)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(f'Erreur lors de la numérisation : {e}'.encode())
        else:
            # Gérer d'autres routes si nécessaire
            super().do_POST()
        

def run(server_class=HTTPServer, handler_class=MyCGIHandler, port=8888):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Serveur actif sur http://localhost:{port}')
    httpd.serve_forever()


 #Page d'accueil avec les boutons "Utilisateur" et "Admin"
@app.route('/')
def home():
    return render_template('home.html')


# Page d'authentification pour l'admin
@app.route('/admin', methods=['GET', 'POST'])
def admin():
    error = None
    if request.method == 'POST':
        # Vérifiez les informations d'authentification ici (par exemple, un simple mot de passe)
        username = request.form['username']
        password = request.form['password']
        #print(f"Username: {username}, Password: {password}")
        # Vérifiez l'identifiant et le mot de passe
        admin = get_admin_by_username(username)
        #print(f"Admin data: {admin}")
        if admin and check_password(password, admin['mot_de_passe'], None):
            # Authentification réussie, redirigez vers le tableau de bord admin
            return redirect(url_for('admin_dashboard'))
        else:
            # Affichez un message d'erreur si l'authentification échoue
            error = 'Identifiant ou mot de passe incorrect'

    return render_template('admin_login.html', error=error)


    
def check_password(input_password, stored_hash, salt=None):
    if salt is not None:
        input_hash = hashlib.sha256((input_password + salt).encode('utf-8')).hexdigest()
    else:
        input_hash = hashlib.sha256(input_password.encode('utf-8')).hexdigest()

    return input_hash == stored_hash




def get_admin_by_username(username):
    # Paramètres de connexion à la base de données MySQL
    db_config = {
        'host': 'localhost',
        'user': 'root',
        'password': 'root',
        'db': 'stationblanche',
        'charset': 'utf8mb4',
        'cursorclass': pymysql.cursors.DictCursor
    }

    # Créez une connexion à la base de données
    connection = pymysql.connect(**db_config)

    try:
        # Créez un objet curseur pour exécuter des requêtes SQL
        with connection.cursor() as cursor:
            # Requête SQL pour récupérer l'administrateur par nom d'utilisateur
            sql = "SELECT identifiant, mot_de_passe FROM administrateur WHERE identifiant=%s"
            cursor.execute(sql, (username,))

            # Récupérez le premier résultat (il ne devrait y en avoir qu'un seul, car les identifiants sont censés être uniques)
            admin = cursor.fetchone()

            return admin

    finally:
        # Fermez la connexion à la base de données
        connection.close()



    
# Page d'administration (redirection réussie)
@app.route('/admin_dashboard')
def admin_dashboard():
    sql = "SELECT * FROM cles_usb"

    connection = pymysql.connect(**db_config)
    
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            # Récupérez toutes les lignes de résultats
            cles_usb_data = cursor.fetchall()
    finally:
        connection.close()

    # Passez les données à votre modèle HTML
    return render_template('admin_dashboard.html', cles_usb_data=cles_usb_data)


@app.route('/get_cles_usb_data')
def get_cles_usb_data():
    sql = "SELECT * FROM cles_usb"

    connection = pymysql.connect(**db_config)
    
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            # Récupérez toutes les lignes de résultats
            cles_usb_data = cursor.fetchall()

        # Renvoie les données en tant que réponse JSON
        return jsonify(cles_usb_data)
    finally:
        connection.close()
     
    
# Route pour la page utilisateur
@app.route('/user', methods=['GET'])
def user_page():
    return render_template('user.html')

# Route pour déclencher la numérisation
@app.route('/trigger-scan', methods=['POST'])
def trigger_scan():
    try:
        # Exécuter le script shell pour numériser la clé USB
        scan_script_path = '/home/marieme/Station-Blanche-USB/station-blanche/scan_and_log.sh'  
        subprocess.run(['bash', scan_script_path], check=True)
        
        # Maintenant, exécutez également le script Python pour vérifier la clé USB
        subprocess.run(['python3', '/home/marieme/Station-Blanche-USB/web/extraction_hash.py'], check=True)
        
        return 'La numérisation a été déclenchée avec succès.'
    except subprocess.CalledProcessError as e:
        return f'Erreur lors de la numérisation : {e}', 500

if __name__ == '__main__':
    app.run(debug=True)



