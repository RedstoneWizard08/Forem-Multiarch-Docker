const c = process.env.COMMUNITY;
if(!c) {
    console.log("DEV(local)");
    process.exit(0);
}

console.log(c);
process.exit(0);