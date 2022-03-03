const s = process.env.SECRET;
if(!s) {
    console.log("secret");
    process.exit(0);
}

console.log(s);
process.exit(0);