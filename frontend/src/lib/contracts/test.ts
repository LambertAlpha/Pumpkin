import { AdoptPet } from "./index";
import { useSignAndExecuteTransaction } from "@mysten/dapp-kit";

async function testContractCalls() {
    const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();

    try {
        // // 1. 测试查询状态
        // console.log("测试查询状态...");
        // const state = await queryState();
        // console.log("当前状态：", state);

        // 2. 测试创建宠物
        console.log("测试创建宠物...");
        const petName = "TestPet";
        const transaction = await AdoptPet(petName);
        
        // 执行交易
        try {
            const result = await signAndExecuteTransaction({
                transaction: transaction
            });
            console.log("创建宠物交易结果：", result);
        } catch (error) {
            console.error("执行交易失败：", error);
        }

    } catch (error) {
        console.error("测试失败：", error);
    }
}

// 运行测试
testContractCalls();