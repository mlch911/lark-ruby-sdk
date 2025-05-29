module Lark
  module Apis
    module Im
      # 获取用户或机器人所在的群列表
      # @param sort_type [String] 排序方式。可选值：
      #   - ByCreateTimeAsc: 按创建时间升序（默认值）
      #   - ByActiveTimeDesc: 按活跃时间降序排列。因群组活跃时间变动频繁，使用 ByActiveTimeDesc 排序方式可能会造成群组遗漏或重复。因为每次分页时，会重新计算活跃时间。
      # @param page_size [Integer] 分页大小，默认20，最大值为100
      # @param page_token [String] 分页标记，第一次请求不填，表示从头开始遍历；分页查询结果还有更多项时会同时返回新的 page_token，下次遍历可采用该 page_token 获取查询结果
      # API doc: https://open.feishu.cn/document/server-docs/group/chat/list?appId=cli_a3a81c34a03dd013
      def list_groups(sort_type: 'ByCreateTimeAsc', page_size: nil, page_token: nil)
        get('im/v1/chats', params: {
          sort_type: sort_type,
          page_size: page_size,
          page_token: page_token
        }.compact)
      end

      # 获取用户或机器人所在的所有群列表（自动处理分页）
      # @param sort_type [String] 排序方式。可选值：
      #   - ByCreateTimeAsc: 按创建时间升序（默认值）
      #   - ByActiveTimeDesc: 按活跃时间降序排列。因群组活跃时间变动频繁，使用 ByActiveTimeDesc 排序方式可能会造成群组遗漏或重复。
      # @param page_size [Integer] 每次请求的分页大小，默认100，最大值为100
      # @return [Array] 所有群组数据的数组
      def list_all_groups(sort_type: 'ByCreateTimeAsc', page_size: 100)
        results = []
        page_token = nil

        loop do
          data = list(sort_type: sort_type, page_size: page_size, page_token: page_token).data

          # 添加当前页的数据
          results.concat(data['data']['items']) if data['data'] && data['data']['items']

          # 获取下一页的 token
          page_token = data['data']['page_token']

          # 如果没有更多数据，退出循环
          break unless data['data']['has_more'] == true
        end

        results
      end

      # 获取用户或机器人所在的群列表
      # @param query [String] 搜索内容复。因为每次分页时，会重新计算活跃时间。
      # @param page_size [Integer] 分页大小，默认20，最大值为100
      # @param user_id_type 用户 ID 类型
      #   可选值：open_id、user_id、union_id
      #   默认值：open_id
      # @return [Array] 群组
      #
      # API doc: https://open.feishu.cn/document/server-docs/group/chat/search?appId=cli_a3a81c34a03dd013
      def search_groups(query, user_id_type: :open_id)
        result = get('im/v1/chats/search', params: {
          query: query,
          user_id_type: user_id_type
        })
        result.data['data']['items']
      end

      # receive_id_type:
      #   可选值：open_id、user_id、union_id、email、chat_id
      #   默认值：open_id
      # payload 结构 --
      #   receive_id: 消息接收者
      #   content：消息内容
      #   msg_type：消息类型
      # API doc: https://open.feishu.cn/document/server-docs/im-v1/message/create
      # 内容文档: https://open.feishu.cn/document/server-docs/im-v1/message-content-description/create_json#45e0953e
      def send_message(payload, receive_id_type: :open_id)
        post 'im/v1/messages', payload, params: { receive_id_type: receive_id_type }.compact
      end

      # Sends a markdown message to a specified receiver.
      #
      # @param title [String] The title of the message.
      # @param [String] markdown  markdown内容。注意只支持部分 markdown 语法。
      #                           若需要使用图片，markdown 中的图片链接必须为通过「上传图片」接口上传的图片的 image_key，直接使用图片链接无法发送
      #                           详见https://open.feishu.cn/document/ukTMukTMukTM/uADOwUjLwgDM14CM4ATN。
      # @param [Hash] btn_dic      配置按钮。key 为按钮文字，value 为按钮点击跳转的链接。
      # @param receive_id [String] The ID of the message receiver.
      # @param receive_id_type [Symbol] The type of receiver ID. Optional values: :open_id, :user_id, :union_id, :email, :chat_id. Default is :open_id.
      #
      # API doc: https://open.feishu.cn/document/server-docs/im-v1/message/create
      # 内容文档: https://open.feishu.cn/document/server-docs/im-v1/message-content-description/create_json#45e0953e
      #
      # @return [HTTP::Response] The response from the API call.
      def send_markdown_message(title: '', markdown:, btn_dic: {}, receive_id:, receive_id_type: :open_id)
        if btn_dic.empty?
          content = {
            zh_cn: {
              title: title,
              content: [
                [
                  {
                    tag: 'md',
                    text: markdown
                  }
                ]
              ]
            }
          }
          send_message({
            receive_id: receive_id,
            content: content.to_json,
            msg_type: 'post'
          },
          receive_id_type: receive_id_type)
        else
          body = {
            receive_id: receive_id,
            msg_type: 'interactive',
            card: {
              elements: [{
                tag: 'div',
                text: {content: message, tag: 'lark_md'},
              }],
              header: {
                title: {
                  content: title,
                  tag: 'plain_text'
                }
              }
            }
          }
          unless btn_dic.empty?
            actions = []
            btn_dic.each_pair do |btn, url|
              actions.push({ tag: 'button',
                            text: {
                              tag: 'plain_text',
                              content: btn.to_s
                            },
                            type: 'primary',
                            url: url })
            end
            body[:card][:elements].push({ tag: 'action',
                                          actions: actions })
          end
          body[:content] = body[:card].to_json
          body[:card] = nil
          send_message(body, receive_id_type: receive_id_type)
        end
      end

      def upload_image(image, image_type)
        post_form 'im/v1/images', { image: HTTP::FormData::File.new(image), image_type: image_type }
      end

      def download_image(image_key, params = {})
        get "im/v1/images/#{image_key}", params: params, as: :file
      end

      # member_id_type:
      #   可选值：user_id、union_id、open_id、app_id
      #   默认值：open_id
      # succeed_type:
      #   0：兼容之前的策略，不存在/不可见的 ID 会拉群失败，并返回错误响应。存在已离职 ID 时，会将其他可用 ID 拉入群聊，返回拉群成功的响应。
      #   1：将参数中可用的 ID 全部拉入群聊，返回拉群成功的响应，并展示剩余不可用的 ID 及原因。
      #   2：参数中只要存在任一不可用的 ID ，就会拉群失败，返回错误响应，并展示出不可用的 ID。
      def add_members_to_chat(chat_id, id_list, member_id_type: :open_id, succeed_type: 1)
        post "im/v1/chats/#{chat_id}/members", { id_list: id_list }, params: {
          member_id_type: member_id_type,
          succeed_type: succeed_type
        }.compact
      end

      def remove_members_from_chat(chat_id, id_list, member_id_type: :open_id)
        delete "im/v1/chats/#{chat_id}/members", { id_list: id_list }, params: {
          member_id_type: member_id_type
        }.compact
      end

      def delete_chat(chat_id)
        delete "im/v1/chats/#{chat_id}"
      end
    end
  end
end
