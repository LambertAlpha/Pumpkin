import { getFullnodeUrl, SuiClient} from "@mysten/sui/client";
import { createNetworkConfig } from "@mysten/dapp-kit";
import { SuiGraphQLClient } from "@mysten/sui/graphql";

const { networkConfig, useNetworkVariable, useNetworkVariables } =
  createNetworkConfig({
    testnet: {
      url: getFullnodeUrl("testnet"),
      packageID: "0xd5ae24118c6577399944de61232daeae95509725a42e2434ac0e64d4c760e3bd",
      state: "0xa861fe43f96a1b82265fa3c04d51a548001c331c3d2b5c32b44572ae9ceb79c3",
    },
  });

const suiClient = new SuiClient({
  url: networkConfig.testnet.url,
});

const suiGraphQLClient = new SuiGraphQLClient({
  url: `https://sui-testnet.mystenlabs.com/graphql`,
});

export { useNetworkVariable, useNetworkVariables, networkConfig, suiClient, suiGraphQLClient };