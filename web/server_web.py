# -*- coding: utf-8 -*-
"""
Created on Mon Oct 30 06:34:46 2023
@author: marie
"""

from flask import Flask, render_template, request, redirect, url_for, jsonify
from http.server import CGIHTTPRequestHandler, HTTPServer
import subprocess
import pymysql
import hashlib
import webbrowser
import logging

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
            scan_script_path = '/home/marieme/projet_stationblanche/Station-Blanche-USB/station-blanche/scan_and_log.sh'
            try:
                subprocess.run(['bash', scan_script_path], check=True)
                subprocess.run(['python3', '/home/marieme/projet_stationblanche/Station-Blanche-USB/web/extraction_hash.py'], check=True)
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
            super().do_POST()

def run(server_class=HTTPServer, handler_class=MyCGIHandler, port=8888):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Serveur actif sur http://localhost:{port}')
    httpd.serve_forever()

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/admin', methods=['GET', 'POST'])
def admin():
    error = None
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        admin = get_admin_by_username(username)
        if admin and check_password(password, admin['mot_de_passe'], None):
            return redirect(url_for('admin_dashboard'))
        else:
            error = 'Identifiant ou mot de passe incorrect'
    return render_template('admin_login.html', error=error)

def check_password(input_password, stored_hash, salt=None):
    if salt is not None:
        input_hash = hashlib.sha256((input_password + salt).encode('utf-8')).hexdigest()
    else:
        input_hash = hashlib.sha256(input_password.encode('utf-8')).hexdigest()
    return input_hash == stored_hash

def get_admin_by_username(username):
    connection = pymysql.connect(**db_config)
    try:
        with connection.cursor() as cursor:
            sql = "SELECT identifiant, mot_de_passe FROM administrateur WHERE identifiant=%s"
            cursor.execute(sql, (username,))
            admin = cursor.fetchone()
            return admin
    finally:
        connection.close()

@app.route('/admin_dashboard')
def admin_dashboard():
    sql = "SELECT * FROM cles_usb"
    connection = pymysql.connect(**db_config)
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            cles_usb_data = cursor.fetchall()
    finally:
        connection.close()
    return render_template('admin_dashboard.html', cles_usb_data=cles_usb_data)

@app.route('/get_cles_usb_data')
def get_cles_usb_data():
    sql = "SELECT * FROM cles_usb"
    connection = pymysql.connect(**db_config)
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            cles_usb_data = cursor.fetchall()
        return jsonify(cles_usb_data)
    finally:
        connection.close()

@app.route('/user', methods=['GET'])
def user_page():
    return render_template('user.html')

@app.route('/trigger-scan', methods=['POST'])
def trigger_scan():
    try:
        scan_script_path = '/home/marieme/projet_stationblanche/Station-Blanche-USB/station-blanche/scan_and_log_suggestion.sh'
        subprocess.run(['bash', scan_script_path], check=True)
        subprocess.run(['python3', '/home/marieme/projet_stationblanche/Station-Blanche-USB/web/extraction_hash.py'], check=True)
        connection = pymysql.connect(**db_config)
        try:
            with connection.cursor() as cursor:
                sql = "SELECT statut FROM cles_usb WHERE statut='OK'"
                cursor.execute(sql)
                result = cursor.fetchone()
                if result:
                    webbrowser.open('/home/marieme/projet_stationblanche/Station-Blanche-USB/web/templates/accepter.html')
                else:
                    webbrowser.open('/home/marieme/projet_stationblanche/Station-Blanche-USB/web/templates/refuser.html')    
        finally:
            connection.close()
        return 'La numérisation a été déclenchée avec succès.'
    except subprocess.CalledProcessError as e:
        return f'Erreur lors de la numérisation : {e}', 500

if __name__ == '__main__':
    app.run(debug=True)

