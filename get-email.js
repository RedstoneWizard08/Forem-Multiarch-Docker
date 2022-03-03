const e = process.env.EMAIL;
if(!e) {
    console.log("webmaster@localhost");
    process.exit(0);
}

console.log(e);
process.exit(0);