const { spawn } = require('child_process');

const commandlineArgs = process.argv.slice(2);

function execute(command) {
    return new Promise((resolve, reject) => {
        const onExit = (error) => {
            if (error) {
                return reject(error);
            }
            resolve();
        };
        spawn(command.split(' ')[0], command.split(' ').slice(1), {
            stdio: 'inherit',
            shell: true,
        }).on('exit', onExit);
    });
}

async function performAction(rawArgs) {
    const action = rawArgs[0];
    const network = rawArgs[1];

    if (action === 'deploy') {
        if (network === 'rinkeby') {
            await execute(
                `source .env
                forge script script/ProfileNFT.s.sol:MyScript --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv`
            );
        }

    }
}

performAction(commandlineArgs);