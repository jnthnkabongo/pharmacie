-- =====================================================
-- CREATION BASE DE DONNEES
-- =====================================================

CREATE DATABASE IF NOT EXISTS pharmacie_erp;
USE pharmacie_erp;

-- =====================================================
-- TABLE PHARMACIES
-- =====================================================

CREATE TABLE pharmacies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    telephone VARCHAR(20),
    adresse VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE ROLES (DOIT ETRE AVANT USERS)
-- =====================================================

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    description TEXT
);

-- =====================================================
-- TABLE USERS
-- =====================================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    telephone VARCHAR(20),
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE CATEGORIES
-- =====================================================

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    description TEXT
);

-- =====================================================
-- TABLE FOURNISSEURS
-- =====================================================

CREATE TABLE fournisseurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    telephone VARCHAR(20),
    adresse VARCHAR(255),
    email VARCHAR(100)
);

-- =====================================================
-- TABLE PRODUITS
-- =====================================================

CREATE TABLE produits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    categorie_id INT NULL,
    fournisseur_id INT NULL,
    nom VARCHAR(150) NOT NULL,
    description TEXT,
    code_barre VARCHAR(100),
    prix_achat DECIMAL(10,2),
    prix_vente DECIMAL(10,2),
    date_expiration DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE,
    FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE SET NULL,
    FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id) ON DELETE SET NULL
);

-- =====================================================
-- TABLE STOCKS
-- =====================================================

CREATE TABLE stocks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produit_id INT NOT NULL UNIQUE,
    quantite INT DEFAULT 0,
    seuil_alerte INT DEFAULT 5,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE CLIENTS
-- =====================================================

CREATE TABLE clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    telephone VARCHAR(20),
    adresse VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE VENTES
-- =====================================================

CREATE TABLE ventes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    vendeur_id INT NOT NULL,
    client_id INT NULL,
    montant_total DECIMAL(12,2) NOT NULL,
    mode_paiement ENUM('cash','mobile_money','carte') DEFAULT 'cash',
    type_vente ENUM('comptant','credit') DEFAULT 'comptant',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
    FOREIGN KEY (vendeur_id) REFERENCES users(id),
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
);

-- =====================================================
-- TABLE VENTE_DETAILS
-- =====================================================

CREATE TABLE vente_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vente_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite INT NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL,

    FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- =====================================================
-- TABLE APPROVISIONNEMENTS
-- =====================================================

CREATE TABLE approvisionnements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    fournisseur_id INT NOT NULL,
    user_id INT NOT NULL,
    montant_total DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
    FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =====================================================
-- TABLE APPROVISIONNEMENT_DETAILS
-- =====================================================

CREATE TABLE approvisionnement_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    approvisionnement_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite INT NOT NULL,
    prix_achat DECIMAL(10,2),
    total DECIMAL(12,2),

    FOREIGN KEY (approvisionnement_id) REFERENCES approvisionnements(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- =====================================================
-- TABLE MOUVEMENTS_STOCK
-- =====================================================

CREATE TABLE mouvements_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    produit_id INT NOT NULL,
    type ENUM('entree','sortie','ajustement') NOT NULL,
    quantite INT NOT NULL,
    reference VARCHAR(100),
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
    FOREIGN KEY (produit_id) REFERENCES produits(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =====================================================
-- TABLE JOURNAL_AUDIT
-- =====================================================

CREATE TABLE journal_audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pharmacie_id INT NOT NULL,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    table_concernee VARCHAR(100),
    enregistrement_id INT,
    ancienne_valeur TEXT,
    nouvelle_valeur TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);


-- -- =====================================================
-- -- CREATION BASE DE DONNEES
-- -- =====================================================

-- CREATE DATABASE IF NOT EXISTS pharmacie_erp;
-- USE pharmacie_erp;

-- -- =====================================================
-- -- TABLE PHARMACIES
-- -- =====================================================

-- CREATE TABLE pharmacies (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     nom VARCHAR(150) NOT NULL,
--     telephone VARCHAR(20),
--     adresse VARCHAR(255),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- =====================================================
-- -- TABLE USERS
-- -- =====================================================

-- CREATE TABLE users (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     nom VARCHAR(100) NOT NULL,
--     email VARCHAR(100) UNIQUE NOT NULL,
--     password VARCHAR(255) NOT NULL,
--     role_id INT NOT NULL,
--     telephone VARCHAR(20),
--     actif BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE,
--     FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
-- );

-- -- =====================================================
-- -- TABLE ROLES
-- -- =====================================================

-- CREATE TABLE roles (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     nom VARCHAR(50) NOT NULL,
--     description TEXT
-- );

-- -- =====================================================
-- -- TABLE CATEGORIES
-- -- =====================================================

-- CREATE TABLE categories (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     nom VARCHAR(100) NOT NULL,
--     description TEXT
-- );

-- -- =====================================================
-- -- TABLE FOURNISSEURS
-- -- =====================================================

-- CREATE TABLE fournisseurs (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     nom VARCHAR(150) NOT NULL,
--     telephone VARCHAR(20),
--     adresse VARCHAR(255),
--     email VARCHAR(100)
-- );

-- -- =====================================================
-- -- TABLE PRODUITS
-- -- =====================================================

-- CREATE TABLE produits (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     categorie_id INT NULL,
--     fournisseur_id INT NULL,
--     nom VARCHAR(150) NOT NULL,
--     description TEXT,
--     code_barre VARCHAR(100),
--     prix_achat DECIMAL(10,2),
--     prix_vente DECIMAL(10,2),
--     date_expiration DATE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE,
--     FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE SET NULL,
--     FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id) ON DELETE SET NULL
-- );

-- -- =====================================================
-- -- TABLE STOCKS
-- -- =====================================================

-- CREATE TABLE stocks (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     produit_id INT NOT NULL UNIQUE,
--     quantite INT DEFAULT 0,
--     seuil_alerte INT DEFAULT 5,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

--     FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE      
-- );

-- -- =====================================================
-- -- TABLE CLIENTS
-- -- =====================================================

-- CREATE TABLE clients (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     nom VARCHAR(150) NOT NULL,
--     telephone VARCHAR(20),
--     adresse VARCHAR(255),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id) ON DELETE CASCADE
-- );

-- -- =====================================================
-- -- TABLE VENTES
-- -- =====================================================

-- CREATE TABLE ventes (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     vendeur_id INT NOT NULL,
--     client_id INT NULL,
--     montant_total DECIMAL(12,2) NOT NULL,
--     mode_paiement ENUM('cash','mobile_money','carte') DEFAULT 'cash',
--     type_vente ENUM('comptant','credit') DEFAULT 'comptant',
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
--     FOREIGN KEY (vendeur_id) REFERENCES users(id),
--     FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
-- );

-- -- =====================================================
-- -- TABLE VENTE_DETAILS
-- -- =====================================================

-- CREATE TABLE vente_details (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     vente_id INT NOT NULL,
--     produit_id INT NOT NULL,
--     quantite INT NOT NULL,
--     prix_unitaire DECIMAL(10,2) NOT NULL,
--     total DECIMAL(12,2) NOT NULL,

--     FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
--     FOREIGN KEY (produit_id) REFERENCES produits(id),
--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacie(id)
-- );

-- -- =====================================================
-- -- TABLE APPROVISIONNEMENTS
-- -- =====================================================

-- CREATE TABLE approvisionnements (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     fournisseur_id INT NOT NULL,
--     user_id INT NOT NULL,
--     montant_total DECIMAL(12,2),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
--     FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id),
--     FOREIGN KEY (user_id) REFERENCES users(id)
-- );

-- -- =====================================================
-- -- TABLE APPROVISIONNEMENT_DETAILS
-- -- =====================================================

-- CREATE TABLE approvisionnement_details (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     approvisionnement_id INT NOT NULL,
--     produit_id INT NOT NULL,
--     quantite INT NOT NULL,
--     prix_achat DECIMAL(10,2),
--     total DECIMAL(12,2),

--     FOREIGN KEY (approvisionnement_id) REFERENCES approvisionnements(id) ON DELETE CASCADE,
--     FOREIGN KEY (produit_id) REFERENCES produits(id)
-- );

-- -- =====================================================
-- -- TABLE MOUVEMENTS_STOCK
-- -- =====================================================

-- CREATE TABLE mouvements_stock (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     produit_id INT NOT NULL,
--     type ENUM('entree','sortie','ajustement') NOT NULL,
--     quantite INT NOT NULL,
--     reference VARCHAR(100),
--     user_id INT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
--     FOREIGN KEY (produit_id) REFERENCES produits(id),
--     FOREIGN KEY (user_id) REFERENCES users(id)
-- );

-- -- =====================================================
-- -- TABLE JOURNAL_AUDIT
-- -- =====================================================

-- CREATE TABLE journal_audit (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     pharmacie_id INT NOT NULL,
--     user_id INT,
--     action VARCHAR(255) NOT NULL,
--     table_concernee VARCHAR(100),
--     enregistrement_id INT,
--     ancienne_valeur TEXT,
--     nouvelle_valeur TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (pharmacie_id) REFERENCES pharmacies(id),
--     FOREIGN KEY (user_id) REFERENCES users(id)
-- );
