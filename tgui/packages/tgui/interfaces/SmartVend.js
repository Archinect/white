import { map } from 'common/collections';
import { useBackend } from '../backend';
import { Button, NoticeBox, Section, Table } from '../components';
import { Window } from '../layouts';

export const SmartVend = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window resizable>
      <Window.Content scrollable>
        <Section
          title="Хранилище"
          buttons={!!data.isdryer && (
            <Button
              icon={data.drying ? 'stop' : 'tint'}
              onClick={() => act('Dry')}>
              {data.drying ? 'Остановить' : 'Сушить'}
            </Button>
          )}>
          {data.contents.length === 0 && (
            <NoticeBox>
              Невероятно, но {data.name} пуст.
            </NoticeBox>
          ) || (
            <Table>
              <Table.Row header>
                <Table.Cell>
                  Item
                </Table.Cell>
                <Table.Cell collapsing />
                <Table.Cell collapsing textAlign="center">
                  {data.verb ? data.verb : 'Выдать'}
                </Table.Cell>
              </Table.Row>
              {map((value, key) => (
                <Table.Row key={key}>
                  <Table.Cell>
                    {value.name}
                  </Table.Cell>
                  <Table.Cell collapsing textAlign="right">
                    {value.amount}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      content="Один"
                      disabled={value.amount < 1}
                      onClick={() => act('Release', {
                        name: value.name,
                        amount: 1,
                      })} />
                    <Button
                      content="Много"
                      disabled={value.amount <= 1}
                      onClick={() => act('Release', {
                        name: value.name,
                      })} />
                  </Table.Cell>
                </Table.Row>
              ))(data.contents)}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
