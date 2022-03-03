const u = process.env.URL;
if(!u) {
    console.log("localhost:3000");
    process.exit(0);
}

console.log(u.split("://")[1]);
process.exit(0);