<?php
require_once 'database/config.php';
$db = getDB();
$stmt = $db->query("SELECT id, nombre, apellido, foto FROM usuarios");
echo "ID | Name | Photo\n";
echo "---|---|---\n";
while ($row = $stmt->fetch()) {
    $photo = $row['foto'] ?? 'NULL';
    echo $row['id'] . " | " . $row['nombre'] . " " . $row['apellido'] . " | " . $photo . "\n";
}
