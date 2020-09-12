defmodule Esl do
  @behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url() do
    "https://www.erlang-solutions.com"
  end

  @impl Crawly.Spider
  def init() do
    [
      #start_urls: ["https://www.erlang-solutions.com/blog.html"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # set the parsed body
    parsed_body = Floki.parse(response.body)

    # Getting new urls to follow
    urls =
      response.body
      |> Floki.find("a.more")
      |> Floki.attribute("href")

    # Convert URLs into requests
    requests =
      Enum.map(urls, fn url ->
        url
        |> build_absolute_url(response.request_url)
        |> Crawly.Utils.request_from_url()
      end)

    # get the blog_post
    blog_post = Floki.find(parsed_body, "article.blog_post")

    # Extract item from a page, e.g.
    # https://www.erlang-solutions.com/blog/introducing-telemetry.html
    title =
      blog_post
      |> Floki.find("h1:first-child")
      |> Floki.text()

    author =
      blog_post
      |> Floki.find("p.subheading")
      |> Floki.text(deep: false, sep: "")
      |> String.trim_leading()
      |> String.trim_trailing()

    text =
      blog_post
      |> Floki.text()

    %Crawly.ParsedItem{
      :requests => requests,
      :items => [
        %{title: title, author: author, text: text, url: response.request_url}
      ]
    }
  end

  def build_absolute_url(url, request_url) do
    URI.merge(request_url, url) |> to_string()
  end
end
