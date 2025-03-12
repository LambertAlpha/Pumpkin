import { networkConfig } from "@/networkConfig";
import { State, User } from "@/type";
// importSuiClient,  { TransactionBlock } from '@mysten/sui.js/transactions';
// import { useSuiClient } from '@mysten/dapp-kit';
import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";

// import { networkConfig, suiClient, suiGraphQLClient } from "@/networkConfig";
// import { Folder, FolderData, Profile, State, SuiObject, User } from "@/type";
// import { SuiObjectData, SuiObjectResponse, SuiParsedData } from "@mysten/sui/client";
// import { Transaction } from "@mysten/sui/transactions";
// import { isValidSuiAddress } from "@mysten/sui/utils";
// import queryFolderDataContext from "./graphContext";


export const queryState = async (suiClient: SuiClient) => {
    const events = await suiClient.queryEvents({
        query: {
            MoveEventType: `${networkConfig.testnet.packageID}::smart_contract::PetCreated`
        }
    });
    
    const state: State = {
        users: []
    };   
    
    events.data.forEach((event: { parsedJson: unknown }) => {
        const user = event.parsedJson as User;
        state.users.push(user);
    });
    
    return state;
}

/*    public entry fun create_profile(
        name: String, 
        description: String, 
        state: &mut State,
        ctx: &mut TxContext
    )*/

export const AdoptPet = async (name: string): Promise<Transaction> => {
    const tx = new Transaction();
    
    // 設置 gas budget
    tx.setGasBudget(10000000);
    
    // 修改 moveCall 的格式
    tx.moveCall({
        package: networkConfig.testnet.packageID,
        module: "smart_contract",
        function: "adopt_pet",
        arguments: [
            tx.pure.string(name),
            tx.object(networkConfig.testnet.state)
        ]
    });

    console.log('構建的交易：', {
        packageObjectId: networkConfig.testnet.packageID,
        module: "smart_contract",
        function: "adopt_pet",
        arguments: [name, networkConfig.testnet.state],
        typeArguments: []
    });

    return tx;
}