echo "Start creating new accounts\n"
flow accounts create --key 867ed58c072a194871432364471eca2ab6dafa03425b1217610ea455bb1cbacbf477777cd12246c1286b0fd9fe1828433011a49960fe94948574e988aad7b17f
flow accounts create --key 43f8e6f76b8e78a73cb2e6966f905fd5b39e2fdd55004437f1a839b5e014ea4d02d2c9da8233b984d709c98106cb2a7d8cd31db5c01e9fe1c0745d3520ac04a0
flow accounts create --key cd29d47df8f64685eef7442aa928476f01f93acd82783a4598c1517286f1769f5184b7123edd8d41ac49a25f64f964525e6b64efd3f9846a46712b50399777d0
echo "End creating new accounts\n"
echo "Start deploying project\n"
flow project deploy
echo "End deploying project\n"
echo "Start setup token vault\n"
flow transactions send ./transactions/setup_fusd.cdc --signer deploy-account
echo "End setup token vault\n"

echo "Start setup price reader resource\n"
flow transactions send ./transactions/install_price_reader.cdc 0x045a1763c93006ca --signer deploy-account
flow transactions send ./transactions/install_price_reader.cdc 0x120e725050340cab --signer deploy-account
echo "End setup price reader resource\n"

echo "Start write token infos to RaisePool contract using admin resource\n"
flow transactions send ./transactions/setup_tokenInfo.cdc --args-json "$(cat args.json)" --signer deploy-account
echo "End write token infos to RaisePool contract using admin resource\n"
 