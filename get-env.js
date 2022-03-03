const e = process.env.ENVIRONMENT;
if(!e) {
    console.log("development");
    process.exit(0);
}

console.log(e);
process.exit(0);