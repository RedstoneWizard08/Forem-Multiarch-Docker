const u = process.env.URL;
if(!u) {
    console.log("http://");
    process.exit(0);
}

console.log(u.split("://")[0] + "://");
process.exit(0);