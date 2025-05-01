module.exports = {
  apps: [
    {
      name: "atom-game-blk",
      script: "server/dist/index.js",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "0.0.0.0",
      },
      exp_backoff_restart_delay: 100,
      max_memory_restart: "500M",
      time: true,
      merge_logs: true,
      error_file: "logs/pm2_error.log",
      out_file: "logs/pm2_output.log",
      log_date_format: "YYYY-MM-DD HH:mm Z",
    },
  ],
};