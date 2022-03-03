const fs = require("fs");

const path = "/forem/config/webpacker.yml";

fs.writeFileSync(path, `
${fs.readFileSync(path).toString()}
  dev_server:
    https: false
    host: localhost
    port: 3035
    public: localhost:3035
    hmr: false
    # Inline should be set to true if using HMR
    inline: true
    overlay: true
    compress: true
    disable_host_check: true
    use_local_ip: false
    quiet: false
    pretty: false
    headers:
      'Access-Control-Allow-Origin': '*'
    watch_options:
      ignored: '**/node_modules/**'
`);

process.exit(0);