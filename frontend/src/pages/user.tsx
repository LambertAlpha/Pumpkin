import { useCurrentAccount, useSuiClientQuery } from "@mysten/dapp-kit";
import { Container } from "@radix-ui/themes";
import { PetComponent } from "../components/ui/PetComponent";
import { queryState } from "@/lib/contracts";
import { useState, useEffect } from "react";
import type { Pet, User } from "../type";

function User() {
    const account = useCurrentAccount();
    const [userPet, setUserPet] = useState<Pet | null>(null);
    const [loading, setLoading] = useState(false);
    
    // 測試用例 - 後續需要替換為真實數據
    const testPet: Pet = {
        id: "test-pet-1",
        name: "小花",
        owner: "0x123",
        hp: 100,
        level: 1
    };

    // // 查詢用戶的寵物
    // const { data: stateData } = useSuiClientQuery(
    //     'queryState',
    //     () => queryState(),
    //     {
    //         enabled: !!account,
    //     }
    // );

    // useEffect(() => {
    //     if (account && stateData) {
    //         const currentUser = stateData.users.find(
    //             (user: User) => user.owner === account.address
    //         );
    //         if (currentUser) {
    //             setUserPet(testPet); // 暫時使用測試數據
    //         }
    //     }
    // }, [account, stateData]);

    // if (!account) {
    //     return (
    //         <Container>
    //             <Container
    //                 mt="5"
    //                 pt="2"
    //                 px="4"
    //                 style={{ 
    //                     background: "var(--gray-a2)", 
    //                     minHeight: 500,
    //                     display: "flex",
    //                     justifyContent: "center",
    //                     alignItems: "center"
    //                 }}
    //             >
    //                 <div className="text-center">
    //                     請先連接錢包
    //                 </div>
    //             </Container>
    //         </Container>
    //     );
    // }

    return (
        <Container>
            <Container
                mt="5"
                pt="2"
                px="4"
                style={{ 
                    background: "var(--gray-a2)", 
                    minHeight: 500,
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center"
                }}
            >
                <div style={{ display: "flex", justifyContent: "center", width: "100%" }}>
                    {testPet ? (
                        <PetComponent pet={testPet} />
                    ) : (
                        <div className="text-center">
                            你還沒有寵物，請先在首頁領養一隻寵物
                        </div>
                    )}
                </div>
            </Container>
        </Container>
    );
}

export default User;