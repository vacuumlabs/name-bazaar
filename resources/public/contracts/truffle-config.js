module.exports = {
  contracts_directory: './src',
  compilers: {
    solc: {
      version: "native"
    }
  },
  networks: {
   development: {
     host: "127.0.0.1",
     port: 8549,
     network_id: "*"
   },
  },
};
