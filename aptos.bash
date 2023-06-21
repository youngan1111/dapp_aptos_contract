export set MODULE=0xf9ecb89020d67e318321ea2848029d40c1f96d5aecca78f5e75872e7122a786a
export set USER=0x14d09d852039ffd8905f8cbf6d570652f43ca31db9e366ab1b50dcfbb4cf0cd2
export set PETRA=0xf763fe2af78283f67909c9424ecbda781e106011777e7b92561972f33edf0c3a

# 코인 한번에 register
aptos move run \
  --function-id $MODULE::coins::register_coins \
  --profile testnet3
# 코인 개별 유저 지갑에 등록 QVE, mQVE, aQVE, USDC, USDT
aptos move run \
  --function-id 0x1::managed_coin::register \
  --type-args $MODULE::coins::USDC \
  --profile b
# 코인 minting -> module owner만 target address에다가 minting을 해줄 수 있다.
aptos move run \
  --function-id $MODULE::coins::mint_coin_entry \
  --type-args $MODULE::coins::USDC \
  --args address:0x21037806788ab1303c417f39d34b02973f3b786c0eb79605bcec156fad2016b7 u64:10000000000000000 \
  --profile testnet1

# 계좌 resources 확인 100000000 -> '0' 8개가 하나다
curl --request GET \
  --url http://0.0.0.0:8080/v1/accounts/$PETRA/resources \
  --header 'Content-Type: application/json' | jq .
# usdf 잔고 확인
curl --request GET \
  --url http://0.0.0.0:8080/v1/accounts/$USER/resource/0x1::coin::CoinStore%3C0x$MODULE::usdf::USDF%3E \
  --header 'Content-Type: application/json' | jq .
# transfer coin to somewhere else
aptos move run \
  --function-id $MODULE::basic_coin::coin_transfer \
  --type-args $MODULE::usdf::USDF \
  --args address:0xb44a3ed8bff3901819a49dd22ebfa760e75561ba3b4e636639d1f74ffad7dea3 u64:100000000 \
  --profile default
# deposit to mm account
aptos move run \
  --function-id $MODULE::basic_coin::deposit_to_mm_account_entry \
  --type-args $MODULE::usdf::USDF \
  --args u64:100000000 \
  --profile default





# pool 생성하기

# universal stable pool 생성하기 | Pool 생성전에 코인이 먼저 생성되어야함
aptos move run \
  --function-id $MODULE::pool::create_stable_pool \
  --type-args $MODULE::coins::QVE $MODULE::coins::MQVE \
  --profile testnet1
# add_liquidity to my pool
aptos move run \
  --function-id $MODULE::pool::add_liquidity_stable \
  --type-args $MODULE::coins::QVE $MODULE::coins::MQVE \
  --args u64:10000000000000000 u64:10000000000000000 \
  --profile a

# swap qve => mqve
aptos move run \
  --function-id $MODULE::pool::stable_swap \
  --type-args $MODULE::coins::QVE $MODULE::coins::MQVE \
  --args u64:100000000 \
  --profile a

# liquidswap burn lp token
aptos move run \
  --function-id $MODULE::qve_usdf_pool::burn_liquidity \
  --args u64:1000000000 u64:100000000 u64:100000000 \
  --profile testnet
# 풀의 reserve 사이즈 구하기
curl --request POST \
  --url https://fullnode.testnet.aptoslabs.com/v1/view \
  --header 'Content-Type: application/json' \
  --data '{
  "function": "0x98c572593f715bd814aef03711a5a5a1705b8eba67f1686a725502f55fc92bb9::pool::get_reserve_stable",
  "type_arguments": [
    "0x98c572593f715bd814aef03711a5a5a1705b8eba67f1686a725502f55fc92bb9::coins::QVE",
    "0x98c572593f715bd814aef03711a5a5a1705b8eba67f1686a725502f55fc92bb9::coins::MQVE"
  ],
  "arguments": []
}' | jq .

# stake
aptos move run \
  --function-id $MODULE::coins::deposit_coin_entry \
  --type-args $MODULE::coins::QVE \
  --args u64:100000000 \
  --profile a





# pyth 정보 가져오기
curl --request POST \
  --url https://fullnode.testnet.aptoslabs.com/v1/view \
  --header 'Content-Type: application/json' \
  --data '{
  "function": "e077daafd2d520128ef39d770271b0d0b98f565d1e5eb82c068bc8a985d2bb48::deposit_mint::get_aptos_price",
  "type_arguments": [],
  "arguments": []
}' | jq .


# view function get_message
curl --request POST \
  --url http://0.0.0.0:8080/v1/view \
  --header 'Content-Type: application/json' \
  --data '{
  "function": "8fdb0bbefb74e696d61052690ab837dc0b3ba40677f58e249ef561edcbeb0f20::message::get_message",
  "type_arguments": [],
  "arguments": [
   "b44a3ed8bff3901819a49dd22ebfa760e75561ba3b4e636639d1f74ffad7dea3"
  ]
}' | jq .

# get local module info
curl --request GET \
  --url http://0.0.0.0:8080/v1/accounts/$MODULE/module/basic_coin \
  --header 'Content-Type: application/json' | jq .
# get testnet module info
curl --request GET \
  --url https://fullnode.testnet.aptoslabs.com/v1/accounts/$MODULE/modules \
  --header 'Content-Type: application/json' | jq .
# message module의 event 접근
curl --request GET \
  --url http://0.0.0.0:8080/v1/accounts/$USER/events/$MODULE::message::MessageHolder/message_change_events | jq .
