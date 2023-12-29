import os
import hashlib
import mysql.connector

# Fonction pour obtenir le hash de tous les fichiers (vous pouvez adapter cette fonction selon vos besoins)
def get_hash_for_files(directory):
    hash_list = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file not in ['System', 'Volume Information', '~$Exposés']:
                file_path = os.path.join(root, file)
                with open(file_path, 'rb') as f:
                    file_hash = hashlib.sha256(f.read()).hexdigest()
                    hash_list.append(file_hash)
    return hash_list

# Connexion à la base de données
connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="root",
    database="stationblanche"
)

cursor = connection.cursor()

# Simulation de l'ajout des informations dans la base de données
def add_to_database(hash_value):
    query = "INSERT INTO cles_usb (hash) VALUES (%s)"
    cursor.execute(query, (hash_value,))
    connection.commit()

# Main function
if __name__ == "__main__":
    # Supposons que le point de montage de la clé USB est /mnt
    directory_to_scan = '/dev/sdc'
    
    # Obtenez le hash de tous les fichiers
    hashes = get_hash_for_files(directory_to_scan)
    
    for h in hashes:
        # Vérifiez si le hash existe déjà dans la base de données
        cursor.execute("SELECT * FROM cles_usb WHERE hash = %s", (h,))
        result = cursor.fetchone()
        
        if result:
            print(f"Bienvenue, l'ID associé à ce hash est : {result[0]}")
        else:
            # Ajoutez le nouveau hash à la base de données
            add_to_database(h)
            print("Nouveau hash ajouté à la base de données.")

    cursor.close()
    connection.close()


