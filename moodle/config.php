<?php  // Configuração do Moodle — os valores vêm do ficheiro .env
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = getenv('DB_NAME');
$CFG->dbuser    = getenv('DB_USER');
$CFG->dbpass    = getenv('DB_PASSWORD');
$CFG->prefix    = 'mdl_';
$CFG->dboptions = ['dbpersist' => 0, 'dbport' => 5432];

$CFG->wwwroot   = 'https://' . getenv('MOODLE_DOMAIN');
$CFG->sslproxy  = true;               // o HTTPS é tratado pelo Caddy
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02770;
$CFG->routerconfigured = true;        // regra de rewrite para r.php no Apache

// Sessões em Redis (mais rápido com muitos alunos em simultâneo)
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = 'redis';
$CFG->session_redis_port = 6379;
$CFG->session_redis_prefix = 'mdl_sess_';
$CFG->session_redis_acquire_lock_timeout = 120;
$CFG->session_redis_lock_expire = 7200;

// Email
$CFG->smtphosts      = getenv('SMTP_HOST');
$CFG->smtpuser       = getenv('SMTP_USER');
$CFG->smtppass       = getenv('SMTP_PASSWORD');
$CFG->smtpsecure     = getenv('SMTP_SECURE');
$CFG->smtpauthtype   = 'LOGIN';
$CFG->noreplyaddress = getenv('NOREPLY_ADDRESS');

// O código está dentro da imagem: plugins e atualizações fazem-se pelo kit, não pela interface
$CFG->disableupdateautodeploy = true;
$CFG->preventexecpath = true;
$CFG->pathtogs = '/usr/bin/gs';
$CFG->pathtodot = '/usr/bin/dot';
$CFG->aspellpath = '/usr/bin/aspell';

require_once(__DIR__ . '/lib/setup.php');
// Não pôr nada depois desta linha.
