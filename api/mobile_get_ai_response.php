<?php
/**
 * API para el Entrenador de IA - Versión Experta con Generación de Rutinas con Video
 */

ini_set('display_errors', 0);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    require_once __DIR__ . '/../database/config.php';
    require_once __DIR__ . '/auth.php';

    restoreSessionFromHeader();
    if (session_status() === PHP_SESSION_NONE)
        session_start();

    $auth = new Auth();
    if (!$auth->isAuthenticated()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'No estás autenticado']);
        exit;
    }

    $userId = $_SESSION['usuario_id'];
    $input = json_decode(file_get_contents('php://input'), true);
    $mensajeUsuario = isset($input['mensaje']) ? trim($input['mensaje']) : '';
    $historial = isset($input['historial']) ? $input['historial'] : [];

    if (empty($mensajeUsuario))
        throw new Exception("Mensaje vacío");

    $db = getDB();
    $ejerciciosCurados = require_once __DIR__ . '/ejercicios_curados.php';

    // 1. Obtener contexto del usuario y últimos entrenos
    $stmt = $db->prepare("SELECT nombre FROM usuarios WHERE id = ?");
    $stmt->execute([$userId]);
    $nombre = $stmt->fetchColumn() ?: 'Atleta';

    // Obtener el último plan generado para saber qué hizo recientemente
    $stmt = $db->prepare("SELECT titulo, ejercicios_json FROM plan_entrenamiento WHERE usuario_id = ? ORDER BY fecha DESC LIMIT 3");
    $stmt->execute([$userId]);
    $ultimosPlanes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $contextoEntrenos = "";
    foreach ($ultimosPlanes as $p) {
        $contextoEntrenos .= "- " . $p['titulo'] . "\n";
    }

    // Verificar si ya tiene plan para HOY
    $stmt = $db->prepare("SELECT titulo FROM plan_entrenamiento WHERE usuario_id = ? AND fecha = CURDATE()");
    $stmt->execute([$userId]);
    $planHoy = $stmt->fetchColumn();
    $estadoPlanHoy = $planHoy ? "Ya tiene un plan asignado hoy: '$planHoy'" : "No tiene plan asignado hoy (si pide rutina, genérala).";

    // Fecha en español
    setlocale(LC_TIME, 'es_ES.UTF-8', 'es_ES', 'esp');
    $fechaActual = strftime("%A, %d de %B de %Y");

    // 2. Configuración de API
    $apiKey = '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';
    $model = 'deepseek/deepseek-chat';
    $apiUrl = "https://openrouter.ai/api/v1/chat/completions";

    $systemPrompt = "Eres el 'Entrenador Experto' de FTGym. Tu objetivo es guiar al usuario de forma NATURAL y profesional.\n\n";
    $systemPrompt .= "CONTEXTO ACTUAL:\n";
    $systemPrompt .= "- Fecha: $fechaActual\n";
    $systemPrompt .= "- Usuario: $nombre\n";
    $systemPrompt .= "- Estado Plan de Hoy: $estadoPlanHoy\n";
    if ($contextoEntrenos) {
        $systemPrompt .= "- Últimos entrenos realizados:\n$contextoEntrenos\n";
    }
    $systemPrompt .= "\nREGLAS DE PERSONALIDAD Y FORMATO (ESTRICTAS):\n";
    $systemPrompt .= "1. NO USES MARKDOWN: Prohibido usar asteriscos (**) para negritas. Escribe en texto plano solamente.\n";
    $systemPrompt .= "2. FORMATO DEL PLAN: Si generas una rutina, el bloque JSON DEBE ir al final de todo el texto y encerrado EXACTAMENTE entre [[[PLAN: y ]]]. Ejemplo: [[[PLAN:{\"titulo\":\"...\",\"ejercicios\":[]}]]]\n";
    $systemPrompt .= "3. NO MUESTRES EL JSON: El usuario no debe ver código. El bloque JSON debe ser lo último que escribas y estar pegado al final.\n";
    $systemPrompt .= "4. GENERACIÓN DE RUTINAS: DEBES generar entre 6 y 10 ejercicios VARIADOS con Series, Reps, Intensidad y Descanso en la descripción 'd'.\n";
    $systemPrompt .= "5. VIDEOS REALES (CRÍTICO): Los enlaces 'v' DEBEN ser funcionales. Si no estás 100% seguro de un link específico, usa este formato de búsqueda segura: 'https://www.youtube.com/results?search_query=NOMBRE_EJERCICIO'. NO INVENTES IDs como 'v=abcdefg'.\n";
    $systemPrompt .= "6. LONGITUD: Texto plano de hasta 600 caracteres.\n";
    $systemPrompt .= "7. Responde siempre en español.\n";
    $systemPrompt .= "8. EVITA REPETICIONES: No empieces siempre con 'Excelente Joel'. Varía tus saludos.\n";
    $systemPrompt .= "9. GENERACIÓN DE RUTINAS: Solo si te lo piden. Si piden rutina, CUMPLE LA REGLA 4 (5-8 ejercicios).\n";
    $systemPrompt .= "10. DETALLES POR EJERCICIO: En el campo 'd' (descripción) de cada ejercicio del JSON, DEBES incluir: Series, Repeticiones, Intensidad (ej. RPE 8) y Tiempo de descanso (ej. 90 seg).\n";
    $systemPrompt .= "11. NO ENLACES EN EL TEXTO: Los links solo van dentro del bloque JSON.\n";
    $systemPrompt .= "12. NATURALIDAD: Habla como un amigo entrenador. Recuerda los entrenos anteriores para NO repetir grupos musculares seguidos.\n";
    $systemPrompt .= "13. SOLO GENERA EL BLOQUE JSON (PLAN) SI EL USUARIO LO PIDE EXPLÍCITAMENTE (ej. 'dame una rutina', 'genera mi plan', 'cambia el ejercicio', 'variante'). Si el usuario solo saluda, agradece o hace una pregunta teórica sin pedir rutina, NO envíes el bloque PLAN.\n";
    $systemPrompt .= "14. VARIACIONES: Si el usuario pide cambiar, variar o generar una 'nueva rutina' basada en una anterior, DEBES generar el bloque JSON completo con los nuevos ejercicios.\n";
    $systemPrompt .= "15. BASE DE DATOS DE EJERCICIOS (USA ESTOS NOMBRES): Tienes videos reales para estos nombres exactos: ";

    $nombresEjs = [];
    foreach ($ejerciciosCurados as $cat => $ejs) {
        foreach ($ejs as $nombreEj => $links) {
            $nombresEjs[] = $nombreEj;
        }
    }
    shuffle($nombresEjs);
    $systemPrompt .= implode(", ", array_slice($nombresEjs, 0, 30));
    $systemPrompt .= "... y muchos más.\n";
    $systemPrompt .= "16. ENRUTINAMIENTO INTELIGENTE: Si el usuario menciona un grupo muscular (ej. 'pierna'), NO repitas ejercicios de ese grupo en la misma rutina.\n";
    $systemPrompt .= "17. PROGRESIÓN: Sugiere mejoras de peso/reps basándote en el historial si es relevante.\n";
    $systemPrompt .= "18. CALENTAMIENTO Y ENFRIAMIENTO: Si generas una rutina en el JSON, incluye 1-2 ejercicios de movilidad al inicio y estiramientos al final.\n";
    $systemPrompt .= "19. INTENSIDAD: Usa intensidades progresivas (moderada a alta) a lo largo del plan.\n";
    $systemPrompt .= "20. DESCRIPCIÓN DE INTENSIDAD: En el campo 'd' del JSON, especifica la intensidad (RPE o %1RM).\n";
    $systemPrompt .= "21. VARIACIÓN SEMANAL: Varía los ejercicios para cada grupo muscular durante la semana.\n";
    $systemPrompt .= "22. PROGRESIÓN SEMANAL: Sugiere aumentos semanales en ejercicios clave.\n";
    $systemPrompt .= "23. RECUPERACIÓN: Recomienda al menos 48h de descanso para el mismo grupo muscular.\n";
    $systemPrompt .= "24. Si generas la rutina, enumera los ejercicios también en el mensaje de texto principal.\n";

    $systemPrompt .= "\nRECUERDA: NO ENVÍES [[[PLAN:...]]] SI EL USUARIO NO ESTÁ PIDIENDO UNA RUTINA O CAMBÍO DE EJERCICIOS. Si solo te dan las gracias, responde de forma amable pero sin el bloque de plan.\n";

    $nombresEjs = [];
    foreach ($ejerciciosCurados as $cat => $ejs) {
        foreach ($ejs as $nombreEj => $links) {
            $nombresEjs[] = $nombreEj;
        }
    }
    shuffle($nombresEjs);
    $systemPrompt .= implode(", ", array_slice($nombresEjs, 0, 30));
    $systemPrompt .= "... y más. Si usas uno de estos nombres, el video se asignará automáticamente.\n";
    $systemPrompt .= "\n";

    $messages = [["role" => "system", "content" => $systemPrompt]];

    foreach (array_slice($historial, -10) as $msg)
        $messages[] = $msg;
    $messages[] = ["role" => "user", "content" => $mensajeUsuario];

    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        "model" => $model,
        "messages" => $messages,
        "temperature" => 0.7
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json', 'Authorization: Bearer ' . $apiKey]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $apiResponse = curl_exec($ch);
    curl_close($ch);

    $jsonResult = json_decode($apiResponse, true);
    $fullContent = $jsonResult['choices'][0]['message']['content'] ?? "";

    // 3. Procesar si hay un Plan en la respuesta
    $respuestaTexto = $fullContent;
    $nuevoPlan = null;

    if (preg_match('/\[\[\[PLAN:(.*?)\]\]\]/s', $fullContent, $matches)) {
        $planJsonStr = $matches[1];
        $nuevoPlan = json_decode($planJsonStr, true);
        // Limpiamos el texto para que no se vea el JSON raro en la burbuja
        $respuestaTexto = trim(str_replace($matches[0], '', $fullContent));
    }

    // 4. Guardar en Base de Datos si hay plan nuevo
    if ($nuevoPlan) {

        // --- VERIFICACIÓN Y ASIGNACIÓN DE ENLACES CURADOS ---
        if (isset($nuevoPlan['ejercicios']) && is_array($nuevoPlan['ejercicios'])) {
            // Aplanar la lista de ejercicios curados para búsqueda rápida
            $flatEjs = [];
            foreach ($ejerciciosCurados as $cat => $ejs) {
                foreach ($ejs as $nombre => $links) {
                    $flatEjs[mb_strtolower($nombre)] = $links[0]; // Tomamos el primer link por defecto
                }
            }

            foreach ($nuevoPlan['ejercicios'] as &$ejercicio) {
                $nombreBusqueda = mb_strtolower($ejercicio['n']);

                // Intento de coincidencia exacta o parcial
                $linkEncontrado = null;
                if (isset($flatEjs[$nombreBusqueda])) {
                    $linkEncontrado = $flatEjs[$nombreBusqueda];
                } else {
                    // Búsqueda parcial si no hay exacta
                    foreach ($flatEjs as $nombreCurado => $link) {
                        if (strpos($nombreBusqueda, $nombreCurado) !== false || strpos($nombreCurado, $nombreBusqueda) !== false) {
                            $linkEncontrado = $link;
                            break;
                        }
                    }
                }

                if ($linkEncontrado) {
                    $ejercicio['v'] = $linkEncontrado;
                } else {
                    // Si no está en nuestra lista curada, validamos lo que puso la IA o lo vaciamos
                    if (!function_exists('verifyYoutubeLink')) {
                        function verifyYoutubeLink($url)
                        {
                            if (empty($url))
                                return false;
                            // Regex mejorada para soportar shorts, embed y diversos formatos
                            $regex = '/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i';
                            if (!preg_match($regex, $url, $matches)) {
                                return false;
                            }
                            $id = $matches[1];
                            $ch = curl_init("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$id&format=json");
                            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                            curl_setopt($ch, CURLOPT_NOBODY, true);
                            curl_setopt($ch, CURLOPT_TIMEOUT, 2);
                            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                            curl_exec($ch);
                            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                            curl_close($ch);
                            return $code === 200;
                        }
                    }

                    if (!verifyYoutubeLink($ejercicio['v'] ?? '')) {
                        $ejercicio['v'] = ''; // Activa búsqueda en la App
                    } else {
                        // Normalizar a formato estándar para asegurar compatibilidad con el reproductor de Flutter
                        preg_match('/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i', $ejercicio['v'], $m);
                        $ejercicio['v'] = "https://www.youtube.com/watch?v=" . $m[1];
                    }
                }
            }
        }
        // ------------------------------------------

        // Borramos el plan de HOY si ya existe para reemplazarlo
        $stmt = $db->prepare("DELETE FROM plan_entrenamiento WHERE usuario_id = ? AND fecha = CURDATE()");
        $stmt->execute([$userId]);

        $stmt = $db->prepare("INSERT INTO plan_entrenamiento (usuario_id, titulo, ejercicios_json, fecha) VALUES (?, ?, ?, CURDATE())");
        $stmt->execute([
            $userId,
            $nuevoPlan['titulo'],
            json_encode($nuevoPlan['ejercicios'], JSON_UNESCAPED_UNICODE)
        ]);
    }


    // Quitar comillas innecesarias del texto principal que ve el usuario
    $respuestaTexto = str_replace(['"', '“', '”'], '', $respuestaTexto);

    echo json_encode([
        'success' => true,
        'respuesta' => $respuestaTexto,
        'has_new_plan' => ($nuevoPlan !== null),
        'plan' => $nuevoPlan
    ], JSON_UNESCAPED_UNICODE);


} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}